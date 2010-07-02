
class String
  cattr_accessor :taggify_translations
  
  def upcase_first
    empty? ?
      self :
      self[0].chr.capitalize + self[1, size]
  end
  
  def cp_case(s)
    send((:downcase unless s.dup.downcase!) || (:upcase unless s.dup.upcase!) || (:upcase_first unless s.dup.upcase_first!) || :to_s)
  end
  
  def upcase_first!
    self == (result = upcase_first) ? nil : replace(result)
  end
  
  def cp_case!(s)
    self == (result = cp_case(s))   ? nil : replace(result)
  end
  
  def singularize!
    downcase == (result = singularize).downcase ? nil : replace(result)
  end
  
  def pluralize!
    downcase == (result = pluralize).downcase   ? nil : replace(result)
  end
  
  def t(options = {})
    self.split(" ").collect do |string|
      key              = string.include?(".") ? string.dup : "word.#{string}"
      default          = key.split(".").last
      translating_word = key.starts_with?("word.")
    
      key.downcase!
      options[:pluralize]          ||= true
      options[:translate_callback] ||= LOGGER_PROC if RAILS_ENV == "development"

      if options.include? :default
        options[:default] = [options[:default]].flatten << default.humanize
        s = i18n_t key, options
        s = s[:_base] if s.is_a?(Hash)
        value = s.dup
      else
        s = i18n_t key, options.merge({:default => translating_word ? "" : default.humanize})
        value = s.dup
    
        if translating_word
          unless translated = !s.empty?
            key.singularize!
            s = i18n_t key, options.merge({:default => ""})
            value = s.dup
          end
      
          if s.empty?
            s = default.humanize
            value = s.dup
          else
            s = s.pl(options[:count]) unless !options[:pluralize] or (options[:count].nil? and default.dup.pluralize!)
          end
        end
      end
      
      unless s.gsub!(/^=\s+/, "")
        s.cp_case! options[:capitalize] ? default.capitalize : default
      end

      String.taggify_translations ? taggify(string, s, key, value) : s
      
    end.join " "
  end
  
  def s
    E9s::Inflector.singularize self
  end
  
  def pl(count = nil)
    E9s::Inflector.pluralize self, count
  end
  
private

  E9S_OPTIONS = [:count, :pluralize, :capitalize, :translate_callback]
  LOGGER_PROC = Proc.new{|translation, key, options| puts "INFO: I18n.t #{key.inspect}, #{options.inspect}"}
  
  @@i18n_translations = {}

  def i18n_t(key, opts = {})
    options = opts.inject({}) do |hash, (k, v)|
                hash[k] = v.is_a?(String) && v.include?("<i18n") ? v.gsub(/(\<i18n[^\>]+\>)|(\<\/i18n\>)/, "") : v unless E9S_OPTIONS.include?(k)
                hash
              end
    
    k = "#{key.inspect}, #{options.inspect}"
    translation = (@@i18n_translations[k] ||= I18n.t(key, options))

    opts[:translate_callback].try :call, translation, key, options
    
    translation
  end
  
  def taggify(key, value, actual_key, actual_value)
    attrs = {"data-key" => key, "data-actual_key" => actual_key, "data-actual_value" => actual_value}.collect{|k, v| "#{k} = #{v.inspect}"}.join " "
    "<i18n #{attrs}>#{value}</i18n>"
  end
  
end
