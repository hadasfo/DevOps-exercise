pipelineJob('K8s-Worker-Pod-Job') {
    definition {
        cps {
            script("""
                pipeline {
                    agent {
                        kubernetes {
                            defaultContainer 'jnlp'  // 🔹 Ensure 'jnlp' is the default container
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
                                command: ["sleep", "3600"]  # Keeps container alive
                                tty: true
                              - name: psql-client
                                image: postgres:latest
                                command: ["sleep", "3600"]  # Keeps container alive
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
                                        echo "🔍 Retrieving database credentials..."
                                        def dbUser = sh(script: "kubectl get secret postgresql-secret -n default -o jsonpath='{.data.postgres-user}' | base64 --decode", returnStdout: true).trim()
                                        def dbPass = sh(script: "kubectl get secret postgresql-secret -n default -o jsonpath='{.data.postgres-password}' | base64 --decode", returnStdout: true).trim()
                                        
                                        echo "✅ Credentials retrieved successfully."

                                        withEnv(["PGPASSWORD=\${dbPass}", "DB_USER=\${dbUser}"]) {
                                            script {
                                                echo "⏳ Switching to psql-client container..."
                                                container('psql-client') {  // 🔹 Explicitly switch before running commands
                                                    sh '''
                                                    echo "🚀 Connecting to PostgreSQL..."
                                                    psql -h postgresql -U postgres -d devops -c "INSERT INTO logs (run_time) VALUES (NOW());"
                                                    echo "✅ Data successfully inserted into PostgreSQL."
                                                    '''
                                                }
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
