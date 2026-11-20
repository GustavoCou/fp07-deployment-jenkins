
pipeline {
    agent { label 'ci-python-docker' }

    parameters {
        choice(
            name: 'NOVA_VERSAO',
            choices: ['1.0.0', '1.1.0'],
            description: 'Versão que pretende instalar'
        )

        string(
            name: 'VERSAO_ESTAVEL',
            defaultValue: '1.0.0',
            description: 'Última versão estável'
        )

        booleanParam(
            name: 'AUTORIZAR_ROLLBACK',
            defaultValue: false,
            description: 'Autorizar rollback em caso de falha'
        )

        booleanParam(
            name: 'REGISTRY_PRIVADO',
            defaultValue: false,
            description: 'Autenticar num registry privado'
        )
    }

    environment {
        REGISTRY = 'ghcr.io'
        DOCKER_CONFIG = "${WORKSPACE}/.docker-auth"
    }

    stages {

        stage('Validar pré-requisitos') {
            steps {
                sh '''
                    command -v docker
                    command -v bash
                    command -v curl

                    docker info > /dev/null
                    docker compose version

                    test -f scripts/deploy.sh
                    test -f compose.yaml
                    test -f config/.env.prod
                '''
            }
        }

        stage('Autenticação no Registry') {
            when {
                expression { params.REGISTRY_PRIVADO }
            }

            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'registry-credentials',
                        usernameVariable: 'REGISTRY_USER',
                        passwordVariable: 'REGISTRY_PASSWORD'
                    )
                ]) {
                    sh '''
                        mkdir -p "$DOCKER_CONFIG"

                        printf '%s' "$REGISTRY_PASSWORD" |
                        docker login "$REGISTRY" \
                            -u "$REGISTRY_USER" \
                            --password-stdin
                    '''
                }
            }
        }

        stage('Deployment') {
            steps {
                script {
                    env.RESULTADO = sh(
                        script: '''
                            bash scripts/deploy.sh \
                                "$NOVA_VERSAO" \
                                "$VERSAO_ESTAVEL"
                        ''',
                        returnStatus: true
                    ).toString()
                }
            }
        }

        stage('Validar resultado') {
            steps {
                script {
                    if (env.RESULTADO == '0') {
                        echo 'Deployment aprovado!'
                        writeFile file: 'resultado.txt',
                                  text: 'Deployment aprovado'
                    }
                    else if (env.RESULTADO == '2') {
                        echo 'Rollback executado!'
                        writeFile file: 'resultado.txt',
                                  text: 'Falha na nova versão. Rollback executado.'
                        error('Deployment rejeitado. Rollback realizado.')
                    }
                    else {
                        writeFile file: 'resultado.txt',
                                  text: 'Deployment falhou. Verificar logs.'
                        error('Deployment falhou!')
                    }
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'resultado.txt',
                             allowEmptyArchive: true

            sh 'rm -rf "$DOCKER_CONFIG"'
        }
    }
}
