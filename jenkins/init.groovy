import jenkins.model.*
import hudson.model.*
import javaposse.jobdsl.plugin.*
import java.nio.file.*

println "Starting initialization script..."

Thread.start {
    println "Waiting for Jenkins to initialize..."
    sleep(30000)  // Increased sleep time to allow Jenkins to fully start

    def jenkins = Jenkins.get()
    if (jenkins == null) {
        println("Jenkins instance is not ready. Exiting script.")
        return
    }

    def seedJobName = "JobDSL-Seed"

    def existingJob = jenkins.getItem(seedJobName)
    if (existingJob != null) {
        println("JobDSL Seed Job already exists: ${seedJobName}")
    } else {
        println("Creating JobDSL Seed Job: ${seedJobName}")

        def job = jenkins.createProject(FreeStyleProject, seedJobName)
        job.setDisplayName("Seed Job for Kubernetes Worker Pods")

        def dslScriptPath = "/var/jenkins_home/job-dsl.groovy"
        if (!new File(dslScriptPath).exists()) {
            println("ERROR: Job DSL script file not found at ${dslScriptPath}")
            return
        }

        def dslScript = new File(dslScriptPath).text

        def dslBuilder = new ExecuteDslScripts()
        dslBuilder.setScriptText(dslScript)
        dslBuilder.setSandbox(true)

        job.buildersList.add(dslBuilder)
        job.save()

        println("Triggering seed job build...")
        job.scheduleBuild2(0)

        println("JobDSL Seed Job Created and Triggered: ${seedJobName}")
    }
}
