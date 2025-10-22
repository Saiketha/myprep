pipeline {
  agent {
    docker {
      image 'node:20'
      args '-v /var/run/docker.sock:/var/run/docker.sock -u root:root'
    }
  }

  environment {
    REGISTRY = 'mycompany.jfrog.io'
    NPM_REPO = 'npm-release-local'
    IMAGE_NAME = 'my-app'
    IMAGE_TAG  = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
    DOCKER_IMAGE = "${IMAGE_NAME}:${IMAGE_TAG}"
    NPM_REGISTRY = "https://${REGISTRY}/artifactory/api/npm/${NPM_REPO}/"
    NODE_ENV = 'production'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build & Publish Artifact to JFrog') {
      environment {
        JFROG_USER = credentials('JFROG_USER')
        JFROG_TOKEN = credentials('JFROG_TOKEN')
      }
      steps {
        sh 'npm ci'
        sh 'npm run lint'
        sh 'npm test'
        sh 'npm run mutation || true'
        sh 'npm run build'

        // Publish to JFrog npm repo
        sh """
          echo "//${REGISTRY}/artifactory/api/npm/${NPM_REPO}/:_authToken=${JFROG_TOKEN}" > .npmrc
          npm publish --registry=${NPM_REGISTRY}
        """
      }
    }

    stage('Docker Build from Artifact') {
      steps {
        // Download artifact from JFrog
        sh """
          curl -u ${JFROG_USER}:${JFROG_TOKEN} -O https://${REGISTRY}/artifactory/${NPM_REPO}/${IMAGE_NAME}-${IMAGE_TAG}.tgz
        """

        // Build Docker image
        sh """
          docker build -t ${DOCKER_IMAGE} .
          docker images --filter=reference='${DOCKER_IMAGE}'
        """
      }
    }

    stage('Trivy Security Scan') {
      steps {
        sh """
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest \
            image --exit-code 1 --severity HIGH,CRITICAL ${DOCKER_IMAGE} || {
            echo "Trivy found HIGH/CRITICAL vulnerabilities. Failing the build."
            exit 1
          }
        """
      }
    }

    stage('Push Docker Image to Docker Hub') {
      environment {
        DOCKERHUB_USER = credentials('DOCKERHUB_USER')
        DOCKERHUB_TOKEN = credentials('DOCKERHUB_TOKEN')
      }
      steps {
        sh """
          echo ${DOCKERHUB_TOKEN} | docker login -u ${DOCKERHUB_USER} --password-stdin
          docker tag ${DOCKER_IMAGE} ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
          docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
          docker logout
        """
      }
    }

    stage('Edit Helm Chart Values') {
      when { branch 'main' }
      steps {
        script {
          def helmValues = 'charts/my-app/values.yaml'
          sh """
            sed -i -E "s|(repository:.*)|(repository: ${DOCKERHUB_USER}/${IMAGE_NAME})|g" ${helmValues} || true
            sed -i -E "s|(tag:).*|(tag: \"${IMAGE_TAG}\")|g" ${helmValues} || true
          """
        }
      }
    }

    stage('Commit Helm Changes') {
      when { branch 'main' }
      steps {
        withCredentials([usernamePassword(credentialsId: 'GIT_CREDENTIALS', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
          sh """
            git config user.email "ci-bot@mycompany.com"
            git config user.name  "ci-bot"
            git add charts/my-app/values.yaml
            git commit -m "ci: update helm image tag to ${IMAGE_TAG}" || echo "No changes to commit"
            git push https://${GIT_USER}:${GIT_PASS}@$(git config --get remote.origin.url | sed 's#https://##') HEAD:main
          """
        }
      }
    }
  }

  post {
    success {
      echo "Build & Docker image ${DOCKER_IMAGE} pushed successfully."
    }
    failure {
      echo "Build failed!"
    }
    always {
      sh 'docker system prune -f || true'
    }
  }
}