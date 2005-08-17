# The methods added to this helper will be available to all templates in the application.
module ApplicationHelper
    def title(text)
        text.gsub(/<i>(.*?)<\/i>/m, '\1')
    end
end
