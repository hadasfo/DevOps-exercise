import jenkins.model.*
import hudson.model.*
import javaposse.jobdsl.plugin.*
import org.csanchez.jenkins.plugins.kubernetes.*
import java.nio.file.*

println "Starting initialization script..."

Thread.start {
    println "Waiting for Jenkins to initialize..."
    sleep(30000)  // Increased sleep time to allow Jenkins to fully start

    def jenkins = Jenkins.getInstanceOrNull()
    if (jenkins == null) {
        println("Jenkins instance is not ready. Exiting script.")
        return
    }

    // Step 1: Ensure Kubernetes Cloud is Configured
    def k8sCloudName = "kubernetes"
    def existingCloud = jenkins.clouds.getByName(k8sCloudName)

    if (existingCloud == null) {
        println("No Kubernetes cloud found. Creating new one...")

        def k8sCloud = new KubernetesCloud(k8sCloudName)
        k8sCloud.setServerUrl("https://kubernetes.default.svc.cluster.local")
        k8sCloud.setNamespace("jenkins-workers")
        k8sCloud.setJenkinsUrl("http://jenkins.jenkins.svc.cluster.local:8080")
        k8sCloud.setJenkinsTunnel("jenkins-agent.jenkins.svc.cluster.local:50000")
        k8sCloud.setRetentionTimeout(5)
        k8sCloud.setContainerCap(10)

        jenkins.clouds.add(k8sCloud)
        jenkins.save()

        println "✅ Kubernetes cloud configured successfully."
    } else {
        println "✅ Kubernetes cloud is already configured."
    }

    // Step 2: Create JobDSL Seed Job
    def seedJobName = "JobDSL-Seed"
    def existingJob = jenkins.getItem(seedJobName)

    if (existingJob != null) {
        println("✅ JobDSL Seed Job already exists: ${seedJobName}")
    } else {
        println("🚀 Creating JobDSL Seed Job: ${seedJobName}")

        def job = jenkins.createProject(FreeStyleProject, seedJobName)
        job.setDisplayName("Seed Job for Kubernetes Worker Pods")

        def dslScriptPath = "/var/jenkins_home/job-dsl.groovy"
        if (!new File(dslScriptPath).exists()) {
            println("❌ ERROR: Job DSL script file not found at ${dslScriptPath}")
            return
        }

        def dslScript = new File(dslScriptPath).text

        def dslBuilder = new ExecuteDslScripts()
        dslBuilder.setScriptText(dslScript)
        dslBuilder.setSandbox(true)

        job.buildersList.add(dslBuilder)
        job.save()

        println("🔄 Triggering seed job build...")
        job.scheduleBuild2(0)

        println("✅ JobDSL Seed Job Created and Triggered: ${seedJobName}")
    }
}
