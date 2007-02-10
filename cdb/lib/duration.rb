  class Duration
    SECS_HOUR = 60 * 60
    SECS_DAY  = 24 * SECS_HOUR
    MINS_HOUR = 60

    def initialize(secs)
      @secs = secs
    end

    def Duration.secs(secs)
      Duration.new(secs)
    end

    def Duration.mins(mins)
      Duration.new(mins * 60)
    end

    def Duration.hours(hours)
      Duration.new(hours * SECS_HOUR)
    end

    def Duration.days(days)
      Duration.new(days * SECS_DAY)
    end

    def secs
      @secs
    end

    def mins
      (@secs/60).to_i
    end

    def hours
      (@secs/SECS_HOUR).to_i
    end

    def days
      (@secs/SECS_DAY).to_i
    end

    def weeks
      (days/7).to_i
    end

    def by_hours
      [ hours, mins % MINS_HOUR, secs % 60]
    end

    def by_days
      [ days, hours % 24, mins % MINS_HOUR, secs % 60]
    end

    def to_a
      by_days
    end

    def to_s
      Duration.as_str(self.to_a)
    end

    def Duration.as_str(arr)
        s = ""
      case arr.length
        when 4
          if arr[0] > 0
            s << "#{arr[0]}d"
          end
          if arr[1] > 0
            if s.length > 0
              s << ' '
            end
            s << "#{arr[1]}h"
          end
          if arr[2] > 0
            if s.length > 0
              s << ' '
            end
            s << "#{arr[2]}m"
          end
          if arr[3] > 0
            if s.length > 0
              s << ' '
            end
            s << "#{arr[3]}s"
          end
        when 3
          if arr[0] > 0
            s << "#{arr[0]}h"
          end
          if arr[1] > 0
            if s.length > 0
              s << ' '
            end
            s << "#{arr[1]}m"
          end
          if arr[2] > 0
            if s.length > 0
              s << ' '
            end
            s << "#{arr[2]}s"
          end
      end

      s
    end
  end
