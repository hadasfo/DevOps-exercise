pipelineJob('K8s-Worker-Pod-Job-2') {
    definition {
        cps {
            script("""
                pipeline {
                    agent {
                        kubernetes {
                            yaml \"\"\"
                            apiVersion: v1
                            kind: Pod
                            metadata:
                              labels:
                                app: jenkins-worker
                            spec:
                              serviceAccountName: jenkins
                              containers:
                              - name: worker
                                image: bitnami/kubectl:latest
                                command:
                                - cat
                                tty: true
                              - name: psql-client
                                image: postgres:latest
                                command:
                                - cat
                                tty: true
                            \"\"\"
                        }
                    }

                    triggers {
                        cron('H/5 * * * *')
                    }

                    stages {
                        stage('Retrieve Secrets & Insert Data') {
                            steps {
                                container('worker') {
                                    script {
                                        def dbUser = sh(script: "kubectl get secret postgresql-secret -n default -o jsonpath='{.data.postgres-user}' | base64 --decode", returnStdout: true).trim()
                                        def dbPass = sh(script: "kubectl get secret postgresql-secret -n default -o jsonpath='{.data.postgres-password}' | base64 --decode", returnStdout: true).trim()
                                        
                                        withEnv(["PGPASSWORD=\${dbPass}", "DB_USER=\${dbUser}"]) {
                                            container('psql-client') {
                                                sh '''
                                                echo "Recording current date and time into PostgreSQL"
                                                psql -h postgresql -U postgres -d devops -c "INSERT INTO logs (run_time) VALUES (NOW());"
                                                '''
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            """)
        }
    }
}
