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

- Travelling Salesman web app: <https://cbollige.insidelabspages.mathworks.com/matlab-devops/>
- Test report: <https://cbollige.insidelabspages.mathworks.com/matlab-devops/test-reports/junit.html>
- Coverage report: <https://cbollige.insidelabspages.mathworks.com/matlab-devops/code-coverage/cobertura-coverage.html>

# GitHub Action 

A mirror repo https://github.com/yuxudong1024/MATLAB-Travel-Man-DevOps have been added.

Use the Personal access tokens on GitHub to grant the access for user yuxudong1024. Will expire at the begin of Dec 2025.