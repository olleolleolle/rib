
require 'rib/test'

describe Rib::Shell do
  behaves_like :rib

  should 'call after_loop even if in_loop raises' do
    @shell = Rib::Shell.new
    mock(@shell).loop_once{ raise 'boom' }
    mock(@shell).after_loop
    lambda{ @shell.loop }.should.raise(RuntimeError)
  end
end
