# SGViz docker image    

#### Purpose:   
- Automate the configuration review of AWS Security Groups, ACLS VPCs
- Automate the diagramming of our AWS Security groups and VPCs         

*Implementation:*    
We can run this image form Kubernetes as ChronJob schedule at some interval    
Then use the aws-cli push the putput to an S3 audit bucket    

This is an effort to automate the review of AWS VPCs, SG', ACLs etc..

What is SGViz:      
A visualization tool for AWS VPC Security Groups.    
[SGViz](https://github.com/y13i/sgviz)           

how to run it:    
```bash    
docker run -v /Users/<your directory>/Documents:/home/sgviz/diagrams sgviz:latest sgviz generate -k ${sgviz_key_id} -s ${sg_viz_key} -r ${aws_region} --vpc-ids=${vpc-id} --output-path=/home/sgviz/diagrams/${vpc-id}

```    

How to Implement this:
1. Docker build . -t sgviz:latest
2. push the image somewhere
3. set up a k8s CronJob
4. add a command to run the above sgviz command
5. add an aws-cli command to 
```bash
$ aws s3 put <source diagram> <destionation bucket>
```    
to our k8s CronJob
6. add a REST call to some ticketing sytem like Jira to push a ticket to someone go revivew the diagram    

