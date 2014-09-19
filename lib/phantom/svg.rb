
require_relative 'frame.rb'
require_relative 'parser/raster.rb'
require_relative 'parser/svg_reader.rb'
require_relative 'parser/svg_writer.rb'
require_relative 'parser/json_animation_reader.rb'
require_relative 'parser/xml_animation_reader.rb'

module Phantom
  module SVG
    class Base
      include Parser::Raster
      attr_accessor :frames, :width, :height, :loops, :skip_first

      def initialize(path = nil, options = {})
        reset

        add_frame_from_file(path, options) if path
      end

      def reset
        @frames = []
        @width = 0
        @height = 0
        @loops = 0
        @skip_first = false
      end

      def add_frame_from_file(path, options = {})
        create_file_list(path).each do |file|
          case File.extname(file)
          when '.svg'   then  load_from_svg(file, options)
          when '.png'   then  load_from_png(file, options)
          when '.json'  then  load_from_json(file, options)
          when '.xml'   then  load_from_xml(file, options)
          end
        end
      end

      # Creates a blank frame when no arguments are passed
      # Takes another Phantom::SVG object or file path
      def add_frame(frame = nil, options = {})
        if    frame.nil?                              then @frames << Phantom::SVG::Frame.new
        elsif frame.instance_of?(Phantom::SVG::Frame) then @frames << frame
        elsif frame.instance_of?(Phantom::SVG::Base)  then @frames += frame.frames
        elsif frame.instance_of?(String)              then add_frame_from_file(frame, options)
        end
      end

      def set_size
        @width = 0
        @height = 0
        frames.each do |frame|
          @width = frame.width.to_i if frame.width.to_i > @width
          @height = frame.height.to_i if frame.height.to_i > @height
        end
      end

      def save_svg(path)
        set_size if @width.to_i == 0 || @height.to_i == 0

        Parser::SVGWriter.new.write(path, self)
      end

      def save_svg_frame(path, frame, width = nil, height = nil)
        old_width = frame.width
        old_height = frame.height
        frame.width = width unless width.nil?
        frame.height = height unless height.nil?

        write_size = Parser::SVGWriter.new.write(path, frame)

        frame.width = old_width
        frame.height = old_height

        write_size
      end

      def save_apng(path)
        save_rasterized(path)
      end

      # Calculate and return total duration.
      def total_duration
        result = 0.0
        @frames.each_with_index do |frame, i|
          next if i == 0 && @skip_first
          result += frame.duration
        end
        result
      end

      private

      def load_from_svg(path, options)
        reader = Parser::SVGReader.new(path, options)
        if reader.has_animation?
          @width = reader.width
          @height = reader.height
          @loops = reader.loops
          @skip_first = reader.skip_first
        end

        @frames += reader.frames
      end

      def load_from_png(path, options)
        load_raster(path, @frames.size)
      end

      def load_from_json(path, options)
        load_from_reader(Parser::JSONAnimationReader.new(path), options)
      end

      def load_from_xml(path, options)
        load_from_reader(Parser::XMLAnimationReader.new(path), options)
      end

      def load_from_reader(reader, options)
        if @frames.empty?
          @loops = reader.loops
          @skip_first = reader.skip_first
          @frames += reader.frames
          set_size
        elsif reader.skip_first
          @frames += reader.frames.slice(1, reader.frames.length - 1)
        else
          @frames += reader.frames
        end
      end

      def create_file_list(path)
        result = Dir.glob(path).sort_by { |k| k[/\d+/].to_i }
        result << path if result.empty?
        result
      end
    end
  end
end
