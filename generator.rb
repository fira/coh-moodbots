#!/usr/bin/env ruby2.6
# encoding: utf-8
# Moody bind files generator for CoH henchmen?!

# General manual data
player_name = "Mekki"
pet_names = [ "Kirby", "Vayu", "Sagi", "Henry", "Marty", "Larry" ]
subdir = "moodbots"
outdir = "C:/Games/Homecoming/settings/live/"

# Bind data
commandset = [
  [ 'V', 'follow', 'petcom_all follow'  ],
  [ 'G', 'goto',   'petcom_all goto'     ],
  [ 'H', 'stay',   'petcom_all stay'     ],
  [ 'F', 'attack', 'petcom_all attack'   ],
  [ 'C', 'defensive', 'petcom_all defensive'],
  [ 'SHIFT+C', 'aggressive', 'petcom_all aggressive'],
  [ 'CTRL+C', 'passive', 'petcom_all passive']
]

# Random commands that WILL just SCREW YOU UP! Temporarily.
terminal_mischief = [
  "architect", "++autorun", "backward 1",
  "visscale 0", "netgraph 2", "incarnate_unequip_all",
  "info", "inspexec_slot 1", "++lookup", "++lookdown",
  "next_tray", "powers", "powers_togglealloff", "prev_tray",
  "title_change", "petcomname FFG dismiss", "powexecname Self Destruction",
  "petcom_all dismiss", "++disable2D", "ah"
]

# Bind files generation parameters
bf_total = 6000                             # Amount of files (+1)
bf_behavior_cycle = (50..90)                # Length of a behavior cycle
bf_edgy_prob = (380..450)                   # PPM of variations in a same behavior cycle
bf_delay = 1                                # Skip at least this after inserting a variation

# Behaviors: name, occurence modifier, cycle length modifier
behaviors = [
  [  "eager", 1.2, 0.8 ],
  [  "eager", 1.4, 0.7 ],
  [  "eager", 1.4, 0.7 ],
  [  "lazy",  0.7, 0.8 ],
  [  "cynic", 0.6, 0.8 ],
  [  "robot", 1.1, 0.4 ],
  [  "robot", 1.0, 0.6 ],
  [  "robot", 0.8, 0.8 ],
  [ "robot_broken", 1.5, 0.3 ],
  [ "robot_broken", 1.2, 0.4 ],
  [ "robot_broken", 1.0, 0.5 ],
  [ "robot_malf", 0.75, 0.4 ],
  [ "robot_malf", 0.75, 0.4 ],
  [ "butler",  1.2, 0.8 ],
  [ "rularuu", 1.0, 0.3 ],
  [ "fanclub", 1.0, 0.3 ]
]


# ======== RUNTIME
mood = nil
mood_next = 0
mood_opts = nil
announce_mood = false
cycle_prob = 0
delay_count = 0
context = [] # List of lines to sequentially use
sampled_names = []

for bfi in 0..bf_total
  # Start by selecting a mood if needed
  if bfi >= mood_next
	announce_mood = true
	mood_data = behaviors.sample
	mood = mood_data[0]
	cycle_prob = rand(bf_edgy_prob) * mood_data[1]
	mood_next = bfi + rand(bf_behavior_cycle) * mood_data[2]
	context = []

	# Now read the beahvior data
	mood_opts = Hash.new
	announce_opts = Hash.new
	command = [] # Set of sequential commands for several actions in a row
	commandset.each do |key, name, default|
	  mood_opts[name] = []
	  announce_opts[name] = []
	  File.foreach("behaviors/#{mood}/#{name}") do |line|
		if line.empty?
			next
		end
		linecmd = []
		# First character are special ops (+: add to default, >: next line is direct follow-up)
		spl = line.split(' ')
		if /\@/ =~ spl.first
		  linecmd.push("petsay_name %R %@W")
		  linecmd.push("%@C")
		else
		  if /\+/ =~ spl.first
			linecmd.push(default)
		  end
		  linecmd.push(spl[1..].join(' '))
		end
		command.push(linecmd)
		if not />/ =~ spl.first
		  mood_opts[name].push(command)
		  command = []
		end
	  end
	  File.foreach("behaviors/#{mood}/announce") do |line|
	  	if line.empty?
			next
		end
		linecmd = []
		# First character are special ops (+: add to default, >: next line is direct follow-up)
		spl = line.split(' ')
		if /\+/ =~ spl.first
		  linecmd.push(default)
		end
		linecmd.push(spl[1..].join(' '))
		command.push(linecmd)
		if not />/ =~ spl.first
		  announce_opts[name].push(command)
		  command = []
		end
	  end
	end
  end

  # Next generate a bind file according to mood
  target_filename = bfi.to_s.rjust(6, "0")
  nextbf = bfi + 1
  if nextbf > bf_total
	nextbf = 0
  end
  target_filename_next = nextbf.to_s.rjust(6, "0")

  File.open("#{outdir}/#{subdir}/#{target_filename}", "w") do |fd|
	commandset.each do |key, name, default|
	  cmdset = [default]
	  if announce_mood or (rand(1000) < cycle_prob and delay_count < 1)
		if announce_mood
		  context = announce_opts[name].sample.clone
		  sampled_names = []
		elsif context.empty?
		  context = mood_opts[name].sample.clone
		  sampled_names = []
		end
		if not context.empty?
		  cmdset = context.shift.clone
		end
		puts cmdset
		delay_count = bf_delay
	  elsif delay_count > 0
		delay_count = delay_count - 1
	  end
	  if sampled_names.empty?
		sampled_names = pet_names.sample(3)
	  end
	  cmdset.push("bindloadfilesilent #{subdir}/#{target_filename_next}")
	  cmdtext = cmdset.join("$$")
	  cmdtext.gsub!("%R",  sampled_names[0])
	  cmdtext.gsub!("%O1", sampled_names[1])
	  cmdtext.gsub!("%O2", sampled_names[2])
	  cmdtext.gsub!("%P", player_name)
	  cryptic = (0...60).map { ['#','!','@', '1', '?', '!', '_', '0', '.'].to_a[rand(9)] }.join
	  cmdtext.gsub!("%@W", cryptic)
	  cmdtext.gsub!("%@C", terminal_mischief.sample)
	  fd.write("#{key} \"#{cmdtext}\"\n")
	end
  end

  announce_mood = false
end
