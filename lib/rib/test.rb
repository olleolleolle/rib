
require 'pork/auto'
require 'muack'

Pork::Suite.include(Muack::API)

require 'rib'

copy :rib do
  before do
    Rib.disable_plugins
  end

  after do
    Muack.verify
  end

  def shell opts={}
    @shell ||= new_shell(opts)
  end

  def new_shell opts={}
    shell = Rib::Shell.new(opts)
    yield(shell) if block_given?
    shell.before_loop
  end

  def stub_output
    stub(shell).print(is_a(String)){}
    stub(shell).puts(is_a(String)){}
  end

  def readline?
    Rib.constants.map(&:to_s).include?('Readline') &&
      Rib::Readline.enabled?
  end

  def stub_readline meth=:stub
    send(meth, ::Readline).readline(is_a(String), true) do
      (::Readline::HISTORY << str.chomp).last
    end
  end

  singleton_class.module_eval do
    def test_for *plugins, &block
      require 'rib/all' # exhaustive tests
      rest = Rib.plugins - plugins

      before do
        Rib.enable_plugins(plugins)
        Rib.disable_plugins(rest)
      end

      yield

      case ENV['TEST_LEVEL']
        when '0'
        when '1'
          test_level1(rest, block)
        when '2'
          test_level2(rest, block)
        when '3'
          test_level3(rest, block)
        else # test_level3 is too slow because of rr (i guess)
          test_level2(rest, block)
      end
    end

    def test_level1 rest, block
      rest.each{ |target|
        target.enable
        block.call
        target.disable
      }
    end

    def test_level2 rest, block
      rest.combination(2).each{ |targets|
        Rib.enable_plugins(targets)
        block.call
        Rib.disable_plugins(targets)
      }
    end

    def test_level3 rest, block
      return block.call if rest.empty?
      rest[0].enable
      test_level3(rest[1..-1], block)
      rest[0].disable
      test_level3(rest[1..-1], block)
    end
  end
end

def main
  'rib'
end

Rib::Blackhole = Object.new
b = Rib::Blackhole.singleton_class
b.instance_methods(true).each{ |m|
  b.send(:undef_method, m) unless
    [:object_id, :__send__, :__id__].include?(m) }
