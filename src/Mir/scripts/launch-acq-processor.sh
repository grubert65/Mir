if [[ $# -eq 0 ]] 
	then
	echo "Usage: lauch-acq-processors.sh <a campaign label> <a Log::Log4perl config file>"
	exit 0
fi
echo "Launching ACQ Processor for campaign $1"
nohup perl mir-acq-processor.pl --campaign $1 --log_config_params $2 > /home/grubert/projects/Mir/src/Mir/Logs/mir-acq-processor-$1.log 2>&1 &
