[![coverage](https://cbollige.insidelabspages.mathworks.com/matlab-ci-workshop-sko-2025/coverageBadge.svg)](https://cbollige.insidelabspages.mathworks.com/matlab-ci-workshop-sko-2025/code-coverage/cobertura-coverage.html)
[![tests](https://cbollige.insidelabspages.mathworks.com/matlab-ci-workshop-sko-2025/testBadge.svg)](https://cbollige.insidelabspages.mathworks.com/matlab-ci-workshop-sko-2025/test-reports/junit.html)
[![pipeline](https://insidelabs-git.mathworks.com/cbollige/matlab-ci-workshop-sko-2025/badges/main/pipeline.svg)](https://insidelabs-git.mathworks.com/cbollige/matlab-ci-workshop-sko-2025/-/commits/main)

Travelling Salesman apps: 
- <https://cbollige.insidelabspages.mathworks.com/matlab-ci-workshop-sko-2025/>
- <https://ipws-webapps.mathworks.com/webapps/home/>

# MATLAB DevOps

This demo demonstrates the creation of a CI/CD pipeline for a MATLAB application, 
focusing on running unit and equivalence tests, generating and deploying artifacts, 
and publishing test reports within the CI system. 
The pipeline is implemented using both GitLab and GitHub Actions.
The MATLAB application featured in this demo addresses the Traveling Salesman 
Problem using a genetic algorithm. The algorithm undergoes automatic testing, 
packaging, and deployment to a production server, followed by an integration 
test to ensure the deployed algorithm functions correctly. Test reports are 
accessible directly within the CI system for easy review. 
Additionally, an HTML frontend is provided to showcase how the deployed 
algorithm can be invoked from JavaScript.