// android/build.gradle.kts
// ملاحظة: لا نضيف أي repositories هنا — تُدار في settings.gradle.kts

val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    // اجعل مجلد build لكل موديول تحت build/ في جذر المشروع
    layout.buildDirectory.set(newBuildDir.dir(name))

    // تأكّد أن تقييم الموديولات يعتمد على :app أولًا
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}