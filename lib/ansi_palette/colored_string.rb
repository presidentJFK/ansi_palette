require "forwardable"

module AnsiPalette
  START_ESCAPE = "\e[" # "\033["
  END_ESCAPE   = "m"
  RESET_COLOR  = 0

  COLOR_HASH = {
    :black   => { :foreground => 30, :background => 40 },
    :red     => { :foreground => 31, :background => 41 },
    :green   => { :foreground => 32, :background => 42 },
    :yellow  => { :foreground => 33, :background => 43 },
    :blue    => { :foreground => 34, :background => 44 },
    :magenta => { :foreground => 35, :background => 45 },
    :cyan    => { :foreground => 36, :background => 46 },
    :white   => { :foreground => 37, :background => 47 },
  }

  EFFECT_HASH = {
    :reset          => 0,
    :bold           => 1,
    :underline      => 4,
    :blink          => 5,
    :inverse_colors => 7
  }

  COLOR_HASH.each_pair.each do |color, color_codes|

    # defines the following methods:
    #   Black, Red, Green, Yellow, Blue, Magenta, Cyan, White
    #
    # which all return a ColoredString instance
    define_method color.to_s.capitalize do |string|
      AnsiPalette::ColoredString.new(string: string, color: color)
    end

    # defines the following methods:
    #   BlackBg, RedBg, GreenBg, YellowBg, BlueBg, MagentaBg, CyanBg, WhiteBg
    #
    # which all return a ColoredString instance
    define_method "Bg" + color.to_s.capitalize do |string|
      AnsiPalette::ColoredString.new(string: string, background_color: color)
    end

    const_set("#{color.upcase}_FG", color_codes.fetch(:foreground))
    const_set("#{color.upcase}_BG", color_codes.fetch(:background))
  end

  class ColoredString
    extend ::Forwardable

    # @param string [String] the string you would like to colorize
    # @param color [Symbol] the color you would like to affect on the string
    # @param background_color [Symbol] the color you would like to affect on the background
    #   of the string
    # @param modifier [Integer] the ANSI escape code for the modifier you
    #   would like to apply to the string passed in
    def initialize(string:,
                   color: nil,
                   background_color: nil,
                   modifier: nil,
                   bold: false,
                   blink: false)

      @string           = string
      @color            = color
      @background_color = background_color
      @modifier         = modifier
      @bold             = bold
      @blink            = blink
    end

    # Defines the following methods:
    #   reset=, bold=, underline=, blink=, inverse_colors=
    EFFECT_HASH.keys.each do |modifier_method|
      attr_accessor modifier_method
    end

    attr_accessor :modifier

    def colored_string
      set_modifiers          +
        set_foreground_color +
        set_background_color +
        string               +
        reset_color
    end

    alias_method :to_s, :colored_string
    alias_method :to_str, :to_s
    def_delegators :string, :length

    private

    attr_reader :string,
                :color,
                :background_color,
                :modifier

    def set_modifiers
      set_modifier +
        set_blink +
        set_bold +
        set_underline +
        set_blink +
        set_inverse_colors
    end

    EFFECT_HASH.each_pair do |modifier, code|
      define_method "#{modifier}?" do
        instance_variable_get("@#{modifier}")
      end

      define_method "set_#{modifier}" do
        send("#{modifier}?") ? escape_sequence(code.to_s) : ""
      end
    end

    def set_modifier
      !modifier.nil? ? escape_sequence(modifier.to_s) : ""
    end

    def set_foreground_color
      set_color(color, "_FG")
    end

    def set_background_color
      set_color(background_color, "_BG")
    end

    def set_color(color, color_type)
      return "" if color.nil?

      escape_sequence(
        AnsiPalette.const_get(color.to_s.upcase + color_type).to_s
      )
    end

    def reset_color
      escape_sequence(RESET_COLOR.to_s)
    end

    def escape_sequence(content)
      START_ESCAPE + content + END_ESCAPE
    end
  end
end
