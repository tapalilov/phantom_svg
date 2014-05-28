require 'nokogiri'

module Phantom
  module SVG
    class Frame
      attr_accessor :duration, :surface, :width, :height, :namespaces

      def initialize(path = nil, options = {})
        @duration = options[:duration] || 1
        @surface = options[:surface]
        @width = options[:width] || 64
        @height = options[:height] || 64 
        @namespaces = options[:namespaces] || {}

        set_data_from_file(path) if path
      end

      def set_data_from_file(path)
        data = Nokogiri::XML(File.read(path))

        set_namespaces(data.namespaces)

        data.css('svg').each do |svg|
          @width = svg.get_attribute('width')
          @height = svg.get_attribute('height')
          @surface = svg.children
        end
      end

      def set_namespaces(data)
        data.each do |key, value|
          @namespaces[key] = value
        end
      end
    end
  end
end