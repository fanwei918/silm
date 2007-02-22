require 'duration'

class CharacterController < ApplicationController
	before_filter :authenticate
	before_filter :enter_details

	before_filter :authenticate_char_admin, :only => ['consistency']
	before_filter :authenticate_audit_admin, :only => ['notify']

	def notify
		c = Character.find(863)
		
		to = [session[:user]]
		em = Notifications.deliver_status(c, to)
	end

	def index
		return if !session[:user]
	
		perpage = 30
		#@onlineonly = "1"

		# @loggedonly = params['loggedonly'] || "0"
		# @loggedonly = "1" if !session[:user].char_view?
		@onlineonly = params['onlineonly'] || "0"
		@sort = "last_login"
		@sort = params['sort'] if params['sort'] && %w{id character race gold xp last_login status create_on register_on}.index(params['sort'])
		@order = "desc"
		@order = params['order'] if params['order'] && %w{asc desc}.index(params['order'])
		order = "`#{@sort}` #{@order}"
		cond_s = ""
		cond_a = []
		cond_s = "`current_time` > 0 and " if @onlineonly == "1"

		# cond_s = "`race` != 'Bleistift' and " if @loggedonly == "1"

		if session[:user] && session[:user].char_view?
			search = ""
			search = params['search'] if params['search']
			@search = search
			if search != ""
				if Character::StatusFields.index(search)
					cond_s += "`status` like ? "
					cond_a = ['%' + search + '%']
					#i f search == "register"
					#	cond_s += "or (`status` = 'acc' ) "
					# end
					cond_s += "and "
				elsif search =~ /^\d+$/
					cond_s += '`id` = ? and '
					cond_a = [search]
				elsif search =~ /^dm$/i
					cond_s += '(select dm from accounts where accounts.id=account) = \'true\' and '
				else
					search = '%' + search + '%' 
				
					acc = Account.find(:all, :conditions => ['`account` like ?', search])
					cond_s += "("
					cond_s += ("account = ? or " * acc.size)
					cond_s += "`character` like ? or create_key like ? or "
					cond_s += "other_keys like ? or create_ip like ? or race like ? or "
					cond_s += "subrace like ? or "
					cond_s += "class1 like ? or class2 like ? or class3 like ? or "
					cond_s += "status like ? or familiar_name like ? or "
					cond_s += "deity like ? "
					cond_s += ") and "
					cond_a = [acc.map {|n| n.id }, [search] * 12].flatten
				end
			end
		else
			cond_s = "account = ? and "
			cond_a = [session[:user].id]
		end
		cond = [cond_s + " 1=1", cond_a].flatten

		# now do the updating
		if session[:user].char_admin?
			@query = qn = params.keys.map {|n| $1 if n =~ /^character_(\d+)$/}.compact
			qn.each {|cu|
				cn = Character.find(:first, :conditions => ['id = ?', cu])
				next if !cn

				oldstat = cn.status
				cn.update_attributes(params["character_#{cu}"])
				if cn.status != oldstat
					co = Comment.new(:body => "Status: #{oldstat} -> #{cn.status}", :status => 'system')
					co.account = session[:user].id
					co.character = cn.id
					co.save
				end
			}
		end

		if cond.size > 0
			@character_pages, @characters = paginate :characters, :order => order, :conditions => cond, :per_page => perpage
			if @characters.size == 1 && @search != ""
				redirect_to :controller => 'character', :action => 'show', :id => @characters[0].id
				return
			end
		else
			@character_pages, @characters = paginate :characters, :order => order, :per_page => perpage
		end
		condq = "race != 'Bleistift' and `last_login` >= (unix_timestamp() - 60*60*24*30)" +
			(@onlineonly == "1" ? " and `current_time` > 0" : "")

		lv  = Character.find(:all, :conditions => [condq]).map {
				|ch| ch.class1_level + ch.class2_level + ch.class3_level
			}

		max = 0
		lv.each {|n| max += n }
		@average_level = max.to_f / lv.size.to_f


		@latest_comments = Comment.find(:all, :limit => 20, :order => "date desc"
			#:group => "`character`"
		) if
			session[:user] && session[:user].char_view?
	end

	def show
		@debug = []
		order = "id asc"
		if session[:user] && session[:user].char_view?
			@c = Character.find(:first, :conditions => ['id = ?', params[:id]], :order => order)
		else
			@c = Character.find(:first, :conditions => ['id = ? and account = ?', params[:id], session[:user].id], :order => order)
		end
		
		if params['c'] && @c != nil
			@debug << "updating file"
			# Only char_admins may change character status
			if !session[:user].char_admin?
				@debug << "not charadmin"
				@debug << params['c']['status'].inspect
				@debug << @c.status

				if (!params['c']['status'] || params['c']['status'] == "") && @c.status == "new"
					@debug << "updating status"
					params['c']['status'] = "register"
				else
					return
				end
			end

			params['c']['register_on'] = Time.now if @c.register_on.nil? && params['c']['status'] == "register"
			(params['c']['biography'] || "").strip!
			(params['c']['traits'] || "").strip!
			(params['c']['appearance'] || "").strip!

			oldstat = @c.status

			if !@c.update_attributes(params['c'])
				flash[:notice] = "Konnte nicht abspeichern."
				flash[:errors] = @c.errors
			else	
				flash[:notice] = "Abgespeichert."
				status = params['c']['status']

				if status != oldstat
					co = Comment.new(:body => "Status: #{oldstat} -> #{status}", :status => 'system')
					co.account = session[:user].id
					co.character = @c.id
					co.save
				end

				# Send notification to all char_admins if status is now register and was new
				if status == "register" && oldstat == "new"
					to = Account.find(:all, :conditions => ['char_admin = true'])
					Notifications.deliver_register(@c, to)
				end

				# Send notification to user if status != new and status != register
				if status != "new" && status != "register" && status != "register_accept" && session[:user] != @c.account
					to = [@c.account]
					em = Notifications.deliver_status(@c, to)
				end
			end
		end

		if params['comment'] && @c != nil
			params['comment']['status'] = "private"
			params['comment']['status'] = "public" if params['comment']['public'] == "1"
			params['comment'].delete "public"
			
			params['comment']['body'].strip!

			if Comment::count(:conditions => ['account = ? and `character` = ? and body = ?', session[:user].id, params[:id], params['comment']['body']]) > 0
				flash[:notice] = "Bereits einen Kommentar geposted. Werde nicht noch einmal posten."
				return
			end

			c = Comment.new(params['comment'])

			if !session[:user].char_view?
				c.status = 'public'
			end

			c.account = session[:user].id
			c.character = params[:id]
			# c.date = Time.now
			# c.parent = 0

			if !c.save
				flash[:notice] = "Konnte nicht abspeichern!"
				flash[:errors] = c.errors
			else
				flash[:notice] = "Posted."
				
				# Send notification to all char_admins if the owner of the commented on char posted
				if @c.account == session[:user] && c.status == "public" && !session[:user].char_admin?
					to = Account.find(:all, :conditions => ["char_admin = 'true'"])
					Notifications.deliver_comment(c, to)
					flash[:notice] = "Posted, sowie Email an alle char_admins geschickt." if to.size > 0
				end

				# Send notification to the owning account if a public comment was posted by a char_admin
				if session[:user].char_admin? && c.status == "public" 
					to = [c.character.account]
					Notifications.deliver_comment(c, to)
					flash[:notice] = "Posted, sowie Email an Spieler geschickt."
				end
				
			end
		end
	end

	def consistency
		return unless params['run_check']
		
		dupes = []
		Character.find(:all).each do |char|
			
			# Find duplicates in character names
			ch = Character.find(:all, :conditions => ['`character` = ?', char.character])
			dupes << ch if ch.size > 1

			# find duplicates in account names
			ch = Character.find(:all, :conditions => ['`account` = ?', char.account])
			dupes << ch if ch.size > 1

		end


		# flatten the stuff and filter out same rows
		@characters = dupes.flatten.uniq
	end
end
