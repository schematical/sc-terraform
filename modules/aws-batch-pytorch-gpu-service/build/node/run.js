const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const SRC_PATH = '/home/ubuntu/src/dreambooth';
const CONDA_DIR = '/opt/conda/install';
console.log("process.argv", process.argv);
// console.log("process.argv[2]", process.argv[2]);
const ARGS = JSON.parse(process.env.ARGS); // process.argv[2]);

const runSpawn = async (options) => {
    return new Promise((resolve, reject) => {

        const mainCmd = spawn(
            options.cmd,
            options.args,
            options.options
        );

        mainCmd.stdout.on('data', (data) => {
            console.log(`stdout: ${data}`);
        });

        mainCmd.stderr.on('data', (data) => {
            console.error(`stderr: ${data}`);
        });

        mainCmd.on('close', (code) => {
            console.log(`child process ${options.path} exited with code ${code}`);
            return resolve();
        });
    });
}
(async () => {
    const condaExists = fs.existsSync(CONDA_DIR);
    if (!condaExists) {
        await runSpawn({
            path: CONDA_DIR,
            cmd: 'sh',
            args: [`${__dirname}/scripts/install_conda.sh`]
        });
    }

    const srcExists = fs.existsSync(SRC_PATH);
    if (!srcExists) {
        await runSpawn({
            path: SRC_PATH,
            cmd: 'sh',
            args: [`${__dirname}/scripts/install_src.sh`]
        });
    }


    //

    // Use s3 to download the images

    const conceptsList = []
    // We just need the instances URIs
    console.log("INSTANCE_LIST", ARGS);
    for (const instance of ARGS.conceptList) {
        // const parts = instance.split('/');

        const imageDir = `/home/ubuntu/src/dreambooth/images${instance.instanceS3Path}`;
        const imageDirExists = fs.existsSync(imageDir);
        if (!imageDirExists) {
            const options2 = {
                path: SRC_PATH,
                cmd: 'aws',
                args: [`s3`, `cp`, `s3://${process.env.S3_BUCKET}${instance.instanceS3Path}`, imageDir, '--recursive']
            };
            console.log("options2", options2);
            await runSpawn(options2);
        }
        const conceptData = {
            "instance_prompt":      instance.instancePrompt,
            "instance_data_dir":    imageDir,
        }
        if (instance.classS3Path) {
            const classDataDir = `/home/ubuntu/src/dreambooth/images/${instance.classS3Path}`
            const classDataDirExists = fs.existsSync(classDataDir);
            if (!classDataDirExists) {
                const options = {
                    path: SRC_PATH,
                    cmd: 'aws',
                    args: [`s3`, `cp`, `s3://${process.env.S3_BUCKET}/classes/${instance.classS3Path}/`, classDataDir, '--recursive']
                }
                console.log('options', options);
                await runSpawn(options);
            }

            conceptData.class_prompt =  instance.classPrompt;
            conceptData.class_data_dir = classDataDir;
        }

        conceptsList.push(conceptData);
    }

    console.log("conceptsList:", conceptsList);
    // Save the JSON to disk
    fs.writeFileSync("/home/ubuntu/concepts_list.json", JSON.stringify(conceptsList));
    let runArgs = null;
    if (ARGS.runArgs) {
        runArgs = ARGS.runArgs;
    } else {
        const steps = ARGS.steps || 3;
        const outputPath = path.join("/home/ubuntu", ARGS.modelPath)
        console.log("outputDir:", outputPath);
        fs.mkdirSync(outputPath, { recursive: true });
        runArgs = [
            "--mixed_precision", "fp16",
            "/home/ubuntu/src/dreambooth/examples/dreambooth/train_dreambooth.py ",
            "--pretrained_model_name_or_path", "runwayml/stable-diffusion-v1-5 ",
            "--concepts_list", "/home/ubuntu/concepts_list.json",
            "--resolution", 512,
            "--gradient_checkpointing",
            "--use_8bit_adam",
            "--train_batch_size", 1,
            "--sample_batch_size", 1,
            "--gradient_accumulation_steps", 1,
            "--gradient_checkpointing",
            "--num_train_epochs", steps,
            "--output_dir", outputPath
        ];
    }

    await runSpawn({
        cmd: "accelerate launch",
        args: runArgs,
        options: {
            cwd: '/home/ubuntu/src/dreambooth/examples/dreambooth'
        }
    });

    const dirs = fs.readdirSync(outputPath);// .filter(file => fs.statSync(path.join(srcPath, file)).isDirectory())
    const sortedDirs = dirs.sort();
    console.log("SORTED DIRS: ", outputPath, sortedDirs);
    const outputDir = sortedDirs[sortedDirs.length - 1] || "FAILED";
    const outputPathFull = path.join(outputPath, outputDir);
    const options0 = {
        cmd: 'sh',
        args: [`/home/ubuntu/node/scripts/toCkpt.sh`, outputPathFull]
    };
    console.log("options0", options0);
    await runSpawn(options0);
    const checkPointPath = outputPathFull + '.ckpt';
    const options = {path: SRC_PATH,
        cmd: 'aws',
        args: [`s3`, `cp`, checkPointPath, `s3://${process.env.S3_BUCKET}/${ARGS.modelPath}`], // '--recursive']
    }
    console.log('options', options);
    await runSpawn(options);
    console.log("Cleaning up output dir: " + outputPath);
    dirs.forEach((dir) => {
        const outputPathFull = path.join(outputPath, dir);
        console.log("fs.rmSync(outputPathFull ... : " + outputPathFull);
        fs.rmSync(outputPathFull,  { recursive: true, force: true });
    });


// /opt/conda/envs
})();