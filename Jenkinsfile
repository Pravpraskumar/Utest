pipeline {
  agent none
  stages {
    stage('04#Run Unit Tests') {
      agent {
        node {
          label 'INMAT101SP'
        }

      }
      post {
        always {
          emailext(to: 'PraveenKumar.Kuppili@Hexagon.com', subject: 'Unit Test Workflow Results', body: '${FILE, path="'+"${env.WORKSPACE}"+'\\Report_Gen\\FinalRepo.html"}', mimeType: 'text/html')
        }

      }
      steps {
        catchError(buildResult: 'success', message: 'Failed Unit tests Step', stageResult: 'failure') {
          echo 'Add Unit Tests'
          bat(script: 'Call 11_Run_UTScript.bat', label: 'Attach Workflow UTs')
        }

      }
    }

    stage('Project Completed') {
      steps {
        echo 'Project Completed'
      }
    }

  }
  environment {
    Share_Path = '\\\\azdord-fs\\DeliveryQA'
    DB_Path = 'current\\db'
    BIR_Path = 'current\\bir'
    Version = '10.1UT'
    Logfile = 'C:\\JENKINS\\LATESTSETUPS\\10.1UT\\Logfile.txt'
    DB_SID = 'SDBFT'
    CC_Share = '\\\\in-matst09'
    Log_Share = '\\\\INMATADMIN1\\Jenkins\\LatestSetups'
    Server_Name = 'INMATAPEX1'
    Run_Setups = 'false'
    WPF_Path = 'current\\wpf'
    PORTAL_Path = 'current\\portal'
    CLASSIC_Path = 'current\\classic'
    Run_Only = 'P'
    DB_TNS = 'AUBSDB.WORLD'
    HOST_NAME = 'INMATCMT6.ingrnet.com'
  }
  options {
    timestamps()
    timeout(time: 10, unit: 'HOURS')
    ansiColor('xterm')
  }
  triggers {
    cron('H 05 * * *')
  }
}
