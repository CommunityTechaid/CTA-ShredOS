###Things to do

- add a lftp command that copies all the files from a prehook folder on the server to the /usr/bin/scripts directory. This will be the get\_scripts options. 
- create a folder named device\_logs and nwipe\_logs on the server. Pass lftp commands to fetch device_\*.txt to the device\_logs

- The pre hook scripts must be named pre\_something.sh for it work properly. Same for post. They can be in the same directory. 
- The order of execution cannot be guarenteed (within pre and post scripts).  
- If one script fails, the rest of the scripts are ignored. The script.log files stay on the ShredOS fs and are not copied. 


