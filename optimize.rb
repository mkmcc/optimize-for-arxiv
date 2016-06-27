#!/usr/bin/env ruby
#/ optimize.rb: uses ghostscript to optimize pdf files for printing
#/   - in particular, to downsample images to a reasonable resolution
#/ Usage: optimize.rb [-f plot.pdf] [--file plot.pdf]
#/
require 'optparse'

# parse arguments
#
file = __FILE__
fname = nil
ARGV.options do |opts|
  opts.on("-f", "--file=val", String)   { |val| fname = val }
  opts.on_tail("-h", "--help")         { exec "grep ^#/<'#{file}'|cut -c4-" }
  opts.parse!
end


# check inputs
#
warn "ARGV:   #{ARGV.inspect}"
warn "file:   #{fname.inspect}"


# start our work
#
if fname and File.readable?(fname)
  # tell ghostscript to downsample images and optimize for the printer
  #
  # - additional options tell it to downsample everything, to detect
  #   duplicate images, and to use "Average" downsampling
  gsopts = %w{
-sDEVICE=pdfwrite
-dPDFSETTINGS=/printer
-dUseCIEColor
-dDownsampleColorImages=true
-dDownsampleGrayImages=true
-dDownsampleMonoImages=true
-dColorImageDownsampleType=/Average
-dGrayImageDownsampleType=/Average
-dMonoImageDownsampleType=/Average
-dColorImageResolution=300
-dGrayImageResolution=300
-dMonoImageResolution=300
-dColorImageDownsampleThreshold=1.0
-dGrayImageDownsampleThreshold=1.0
-dMonoImageDownsampleThreshold=1.0
-dDetectDuplicateImages=true
-dNOPAUSE
-dQUIET
-dCompatibilityLevel=1.4
-dBATCH}


  # run ghostscript here
  #
  ext  = File.extname(fname)
  base = File.basename(fname, ext)

  # first, vector formats such as pdf, eps, ps...
  if ['.pdf', '.eps', '.ps'].include? ext
    newname = fname.sub(ext, '_opt.pdf')

    cmd = "gs -o #{newname}" + ' ' + gsopts.join(' ') + ' ' + fname

    system cmd + ' >& ' + base + '.out'

  # then raster formats
  elsif ['.png', '.jpg', '.jpeg'].include? ext
    newname = fname.sub(ext, '_opt.pdf')

    # first convert to a pdf using imagemagick
    cmd = "convert" + ' ' + fname + ' deleteme.pdf'
    system cmd

    # now, optimize the pdf
    cmd = "gs -o #{newname}" + ' ' + gsopts.join(' ') + ' ' + 'deleteme.pdf'
    system cmd + ' >& ' + base + '.out'

  # stuff we don't know about.
  else
    puts "skipping file #{fname}..."
  end

end
