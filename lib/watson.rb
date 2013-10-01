$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])

require 'watson/command'
require 'watson/config'
require 'watson/fs'
require 'watson/parser'

module Watson
	# Global flags for forcing debug prints to be ON or OFF
	# Separate ON and OFF so we can force state and still let 
	# individual classes have some control over their prints
	 
	GLOBAL_DEBUG_ON = false
	GLOBAL_DEBUG_OFF = false 

	# [review] - Not sure if module_function is proper way to scope
	# I want to be able to call debug_print without having to use the scope
	# operator (Watson::Printer.debug_print) so it is defined here as a 
	# module_function instead of having it in the Printer class
	# Gets included into every class individually
	module_function

	def debug_print(msg)
		# Print only if DEBUG flag of calling class is true OR 
		# GLOBAL_DEBUG_ON of Watson module (defined above) is true
		# AND GLOBAL_DEBUG_OFF of Watson module (Defined above) is false

		# Sometimes we call debug_print from a static method (class << self)
		# and other times from a class method, and ::DEBUG is accessed differently 
		# from a class vs object, so lets take care of that
		_DEBUG = (self.is_a? Class) ? self::DEBUG : self.class::DEBUG

		print "=> #{msg}" if ( (_DEBUG == true || GLOBAL_DEBUG_ON == true) && (GLOBAL_DEBUG_OFF == false))
	end	

end