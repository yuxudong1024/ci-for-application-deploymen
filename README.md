# Badges
Badges can't be showed in GitHub

[![coverage](https://cbollige.insidelabspages.mathworks.com/matlab-ci-workshop-sko-2025/coverageBadge.svg)](https://cbollige.insidelabspages.mathworks.com/matlab-ci-workshop-sko-2025/code-coverage/coverage.html)
[![tests](https://cbollige.insidelabspages.mathworks.com/matlab-ci-workshop-sko-2025/testBadge.svg)](https://cbollige.insidelabspages.mathworks.com/matlab-ci-workshop-sko-2025/test-reports/test-results.html)
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

## GitHub Action 

A mirror repo https://github.com/yuxudong1024/ci-for-application-deploymen has been added.

Use the Personal access tokens on GitHub to grant the access for user yuxudong1024. Will expire at the begin of Dec 2025

Generate the token at https://github.com/settings/tokens

On Gitlab Repo setting like https://insidelabs-git.mathworks.com/cbollige/matlab-devops/-/settings/repository

Set Mirroring repositories, use your GitHub account username and the personal access token to mirror.

The WebApp and Production server for delopyment and testing run on AWS: https://edison.mathworks-workshop.com:8443

Production Server run as a Docker, you can find all the contents at https://github.com/yuxudong1024/MATLAB-Travel-Man-DevOps/tree/main/Docker/matlab-prodserver/R2024b
