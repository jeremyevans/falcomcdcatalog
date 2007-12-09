module FalcomHelper
  def date_link(date)
    "#{link_to(date.year, :action=>'albums_by_date', :id=>date.year)}-#{'%02i' % date.month }-#{'%02i' % date.day}"
  end
  
  def song_link(song)
    link_to(song.name, "/song/#{song.id}")
  end
  
  def mail_to_maintainer(text = nil)
    mail_to('falcomcdcatalog@falcomcdcatalog.no-ip.org', text)
  end
end
