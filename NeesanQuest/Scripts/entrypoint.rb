$LOAD_PATH << '.'
$LOAD_PATH << 'Scripts'
$LOAD_PATH << 'Scripts/RPG'

ofile = File.open("something.txt", "w")
ofile.write("ROFFLEWAFFLES")
ofile.close()

require "RPG"

rgss_main { SceneManager.run }
