CFLint Extension
===

This is a ColdFusion Builder extension for the CFLint project (https://github.com/ryaneberly/CFLint). 
It lets you scan a project, directory, or file for issues with your code. 
It is currently tied to the CFLint release as of July 30, 2014. 
To update the CFLint bits, simply download the release and copy the jars into the extension's cflint_lib folder. 

Installation is done via the normal CFB behavior. Download the zip from GitHub, extract, and then import via the CFB extensions panel.

Currently the biggest issue is that it does not let you know when it is working. So if it takes a while to generate the report you won't be given feedback that it is busy. 

Requires ColdFusion 10 and the full version of ColdFusion Builder 2 or higher. Note - you must use
the full version of ColdFusion Builder. The Express edition does not support "callback" URLs which is how
I handle opening files from the extension.

In theory it could be backported to ColdFusion 9 if JavaLoader was used.

Updates
===
[8/5/2014] Disabled cf debugging and removed a log.