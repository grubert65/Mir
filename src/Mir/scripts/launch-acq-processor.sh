if [[ $# -eq 0 ]] 
	then
	echo "Usage: lauch-acq-processors.sh <a campaign label>"
	exit 0
fi
echo "Launching ACQ Processor for campaign $1"
nohup perl mir-acq-processor.pl --campaign $1 > /home/grubert/projects/Mir/src/Mir/Logs/mir-acq-processor-$1.log 2>&1 &
