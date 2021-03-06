
class String
  def upcase_first
    empty? ?
      self :
      self[0].chr.capitalize + self[1, size]
  end
  
  def upcase_first!
    self     == (result = upcase_first)       ? nil : replace(result)
  end
  
  def pluralize!
    downcase == (result = pluralize).downcase ? nil : replace(result)
  end
  
  def cp_case(s)
    send((:downcase unless s.dup.downcase!) || (:upcase unless s.dup.upcase!) || (:upcase_first unless s.dup.upcase_first!) || :to_s)
  end
  
  def t(options = {})
    self.split(" ").collect do |string|
      
      key              = string.include?(".") ? string : "word.#{string}"
      default          = key.split(".").last
      translating_word = key.starts_with?("word.")
    
      key.downcase!
      options[:pluralize] ||= true

      if options.include? :default
        options[:default] = [options[:default]].flatten << default.humanize
        s = i18n_t key, options
        s = s[:_base] if s.is_a?(Hash)
      else
        s = i18n_t key, options.merge({:default => translating_word ? "" : default.humanize})
    
        if translating_word
          unless translated = !s.empty?
            s = i18n_t key.singularize, options.merge({:default => ""})
          end
      
          if s.empty?
            s = default.humanize
          else
            s = s.pl(options[:count]) unless !options[:pluralize] or (options[:count].nil? and default.dup.pluralize!)
          end
        end
      end
    
      s.gsub!(/^=\s+/, "") ? s : s.cp_case(options[:capitalize] ? default.capitalize : default)
      
    end.join " "
  end
  
  def s
    E9s::Inflector.singularize self
  end
  
  def pl(count = nil)
    E9s::Inflector.pluralize self, count
  end
  
private

  E9S_OPTIONS = [:count, :pluralize, :capitalize]

  def i18n_t(key, opts = {})
    options = opts.reject{|k, v| E9S_OPTIONS.include?(k)}
    
    if RAILS_ENV == "development"
      puts "INFO: I18n.t #{key.inspect}, #{options.inspect}"
    end
    
    I18n.t key, options
  end
  
end
