
require 'rib'

module Rib::Paging
  extend Rib::Plugin
  Shell.use(self)

  # --------------- Rib API ---------------

  # Print if the it fits one screen, paging it through a pager otherwise.
  def puts str=''
    return super if Paging.disabled?
    if one_screen?(str)
      super
    else
      page_result(str)
    end
  rescue StandardError, SyntaxError => e
    Rib.warn("Error while printing result:\n  #{format_error(e)}")
  end

  # `less -F` can't cat the output, so we need to detect by ourselves.
  # `less -X` would mess up the buffers, so it's not desired, either.
  def one_screen? str
    cols, lines = `tput cols`.to_i, `tput lines`.to_i
    str.count("\n") <= lines &&
      str.gsub(/\e\[[^m]*m/, '').size <= cols * lines
  end

  def page_result str
    less = IO.popen(pager, 'w')
    less.write(str)
    less.close_write
  rescue Errno::EPIPE
    # less quit without consuming all the input
  end

  def pager
    ENV['PAGER'] || 'less -R'
  end
end

pager = ENV['PAGER'] || 'less'

if `which #{pager}`.empty?
  Rib.warn("#{pager} is not available, disabling Rib::Paging")
  Rib::Paging.disable
elsif `which tput`.empty?
  Rib.warn("tput is not available, disabling Rib::Paging")
  Rib::Paging.disable
elsif ENV['TERM'] == 'dumb' || ENV['TERM'].nil?
  Rib.warn("Your terminal is dumb, disabling Rib::Paging")
  Rib::Paging.disable
end
