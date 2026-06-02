import java.util.Locale
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

data class AndroidRustTarget(
    val abi: String,
    val rustTarget: String,
    val clangPrefix: String,
)

val chronowaveRustTargets = listOf(
    AndroidRustTarget(
        abi = "arm64-v8a",
        rustTarget = "aarch64-linux-android",
        clangPrefix = "aarch64-linux-android",
    ),
    AndroidRustTarget(
        abi = "x86_64",
        rustTarget = "x86_64-linux-android",
        clangPrefix = "x86_64-linux-android",
    ),
)

val chronowaveRustCrateDir = rootProject.layout.projectDirectory.dir("../rust/chronowave_core")
val chronowaveRustWorkspaceDir = rootProject.layout.projectDirectory.dir("../rust")
val chronowaveRustJniLibsDir = rootProject.layout.buildDirectory.dir("rust-jniLibs")
val chronowaveCargoTargetDir = rootProject.layout.buildDirectory.dir("rust-target")
val chronowaveAndroidApiLevel = 29
val chronowavePreferredNdkVersion = flutter.ndkVersion.takeIf { it.isNotBlank() }

fun chronowaveAndroidSdkDir(): File {
    val localProperties = Properties()
    val localPropertiesFile = rootProject.file("local.properties")

    if (localPropertiesFile.isFile) {
        localPropertiesFile.inputStream().use(localProperties::load)
        localProperties.getProperty("sdk.dir")?.takeIf { it.isNotBlank() }?.let {
            return File(it)
        }
    }

    sequenceOf("ANDROID_HOME", "ANDROID_SDK_ROOT")
        .mapNotNull { System.getenv(it) }
        .firstOrNull { it.isNotBlank() }
        ?.let { return File(it) }

    error("Android SDK not found. Set sdk.dir in android/local.properties or ANDROID_HOME.")
}

fun chronowaveHasNdkToolchain(ndkDir: File): Boolean =
    File(ndkDir, "toolchains/llvm/prebuilt").isDirectory

fun chronowaveNdkDir(): File {
    val sdkDir = chronowaveAndroidSdkDir()
    val preferredNdkDir = chronowavePreferredNdkVersion
        ?.let { File(sdkDir, "ndk/$it") }
        ?.takeIf(::chronowaveHasNdkToolchain)
    val versionedNdkDirs = File(sdkDir, "ndk")
        .listFiles { file -> file.isDirectory }
        ?.sortedByDescending { it.name }
        ?: emptyList()
    val fallbackNdkDirs = versionedNdkDirs
        .filterNot { preferredNdkDir != null && it.absolutePath == preferredNdkDir.absolutePath }
    val candidates = listOfNotNull(preferredNdkDir) + fallbackNdkDirs + File(sdkDir, "ndk-bundle")

    return candidates.firstOrNull {
        chronowaveHasNdkToolchain(it)
    } ?: error("Android NDK not found under ${sdkDir.absolutePath}. Install an NDK with sdkmanager.")
}

fun chronowaveNdkHostTag(): String {
    val osName = System.getProperty("os.name").lowercase(Locale.US)

    return when {
        osName.contains("windows") -> "windows-x86_64"
        osName.contains("linux") -> "linux-x86_64"
        osName.contains("mac") -> "darwin-x86_64"
        else -> error("Unsupported host OS for Android NDK: $osName")
    }
}

fun chronowaveRustLinker(target: AndroidRustTarget): File {
    val extension = if (System.getProperty("os.name").lowercase(Locale.US).contains("windows")) ".cmd" else ""
    val linker = File(
        chronowaveNdkDir(),
        "toolchains/llvm/prebuilt/${chronowaveNdkHostTag()}/bin/" +
            "${target.clangPrefix}${chronowaveAndroidApiLevel}-clang$extension",
    )

    if (!linker.isFile) {
        error("Android NDK linker not found: ${linker.absolutePath}")
    }

    return linker
}

fun chronowaveCargoLinkerEnvironmentKey(rustTarget: String): String =
    "CARGO_TARGET_${rustTarget.uppercase(Locale.US).replace('-', '_')}_LINKER"

android {
    namespace = "com.yosepyordi.chronowave.chronowave_studio"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.yosepyordi.chronowave.chronowave_studio"
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    sourceSets {
        getByName("debug") {
            jniLibs.srcDir(chronowaveRustJniLibsDir.map { it.dir("debug") })
        }
        getByName("release") {
            jniLibs.srcDir(chronowaveRustJniLibsDir.map { it.dir("release") })
        }
    }
}

flutter {
    source = "../.."
}

val installChronowaveAndroidRustTargets by tasks.registering(Exec::class) {
    group = "rust"
    description = "Install Rust Android targets required by ChronoWave Core."
    commandLine(
        "rustup",
        "target",
        "add",
        *chronowaveRustTargets.map { it.rustTarget }.toTypedArray(),
    )
}

fun registerChronowaveAndroidRustBuildTask(
    buildTypeName: String,
    cargoProfile: String,
) = tasks.register("buildChronowaveCoreAndroid${buildTypeName.replaceFirstChar { it.uppercase() }}") {
    group = "rust"
    description = "Build libchronowave_core.so for Android $buildTypeName ABIs."
    dependsOn(installChronowaveAndroidRustTargets)

    val crateDir = chronowaveRustCrateDir.asFile
    val workspaceDir = chronowaveRustWorkspaceDir.asFile
    val outputBaseDir = chronowaveRustJniLibsDir.map { it.dir(buildTypeName).asFile }
    val cargoTargetDir = chronowaveCargoTargetDir.map { it.dir(buildTypeName).asFile }

    inputs.file(File(crateDir, "Cargo.toml"))
    inputs.file(File(workspaceDir, "Cargo.toml"))
    inputs.file(File(workspaceDir, "Cargo.lock"))
    listOf(
        File(crateDir, "Cargo.lock"),
        File(crateDir, "build.rs"),
    ).filter { it.isFile }.forEach { inputs.file(it) }
    inputs.dir(File(crateDir, "src"))
    inputs.property(
        "chronowaveRustTargets",
        chronowaveRustTargets.map { "${it.abi}:${it.rustTarget}:${it.clangPrefix}" },
    )
    inputs.property("chronowaveAndroidApiLevel", chronowaveAndroidApiLevel)
    inputs.property("chronowavePreferredNdkVersion", chronowavePreferredNdkVersion ?: "")
    inputs.property("chronowaveBuildTypeName", buildTypeName)
    inputs.property("chronowaveCargoProfile", cargoProfile)
    outputs.dir(cargoTargetDir)
    outputs.dir(outputBaseDir)

    doLast {
        delete(outputBaseDir.get())

        chronowaveRustTargets.forEach { target ->
            val cargoArguments = mutableListOf("build", "--target", target.rustTarget)
            if (cargoProfile == "release") {
                cargoArguments.add("--release")
            }

            exec {
                workingDir = crateDir
                commandLine("cargo", *cargoArguments.toTypedArray())
                environment("CARGO_TARGET_DIR", cargoTargetDir.get().absolutePath)
                environment(
                    chronowaveCargoLinkerEnvironmentKey(target.rustTarget),
                    chronowaveRustLinker(target).absolutePath,
                )
            }

            val profileOutputDir = if (cargoProfile == "release") "release" else "debug"
            val sharedLibrary = File(
                cargoTargetDir.get(),
                "${target.rustTarget}/$profileOutputDir/libchronowave_core.so",
            )

            if (!sharedLibrary.isFile) {
                error("Rust Android build did not produce ${sharedLibrary.absolutePath}")
            }

            copy {
                from(sharedLibrary)
                into(File(outputBaseDir.get(), target.abi))
            }
        }
    }
}

val buildChronowaveCoreAndroidDebug = registerChronowaveAndroidRustBuildTask(
    buildTypeName = "debug",
    cargoProfile = "debug",
)
val buildChronowaveCoreAndroidRelease = registerChronowaveAndroidRustBuildTask(
    buildTypeName = "release",
    cargoProfile = "release",
)

tasks.matching { it.name == "mergeDebugJniLibFolders" }.configureEach {
    dependsOn(buildChronowaveCoreAndroidDebug)
}

tasks.matching { it.name == "mergeReleaseJniLibFolders" }.configureEach {
    dependsOn(buildChronowaveCoreAndroidRelease)
}
