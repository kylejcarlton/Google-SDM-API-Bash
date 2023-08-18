# Set terminal and output file type
set terminal pngcairo size 800,600 enhanced font 'Verdana,12' background rgbcolor "#000000"
set output 'HumidityTemperaturePlot.png'

# Set text and grid color
set title textcolor rgb "#FFFFFF"
set xlabel textcolor rgb "#FFFFFF"
set ylabel textcolor rgb "#FFFFFF"
set key textcolor rgb "#FFFFFF"
set grid linecolor rgb "#FFFFFF"
set border linecolor rgb "#FFFFFF"

# Set labels and title
set xlabel 'Time \& Date'
set key center top outside

# y-axis and y2-axis
set yrange [-40:100]
set y2range [-40:100]
set ytics nomirror 10
set y2tics nomirror 10

# Set data file format and column separator
set datafile separator '|'

# Time and x-axis
set timefmt '%m/%d/%Y %H:%M:%S'   # Set the time format of the data
set xdata time                    # Indicate that the x-axis contains time data
set format x "%H:%M\n%b-%d"       # Set the time format for the x-axis labels
set xtics rotate by -45           # Rotate x-axis labels by 45 degrees
set xlabel offset 0,-1            # Move x-axis label to the bottom

# Line styles
set style line 1 lc rgb 'light-blue'
set style line 2 lc rgb '#58B000'
set style line 3 lc rgb '#FF7E00'
set style line 4 lc rgb '#2087BA'

# Plot temperature and humidity from data file
plot 'gnuplot.data' u 1:5 smooth mcsplines linestyle 4 title 'Outdoor Humidity (%)', \
     'gnuplot.data' u 1:2 smooth mcsplines linestyle 1 title 'Humidity (%)', \
     'gnuplot.data' u 1:4 smooth mcsplines linestyle 3 title 'Outdoor Temp (C)', \
     'gnuplot.data' u 1:3 smooth mcsplines linestyle 2 title 'Temp (C)'