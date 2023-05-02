const fs = require('fs');
const { spawn } = require('child_process');
const SRC_PATH = '/home/ubuntu/src/dreambooth';
const CONDA_DIR = '/opt/conda/install';
console.log("process.argv", process.argv);
// console.log("process.argv[2]", process.argv[2]);
const ARGS = JSON.parse(process.env.ARGS); // process.argv[2]);

const runSpawn = async (options) => {
    return new Promise((resolve, reject) => {
        // console.log("Did not find " + options.path + " installing");

        const mainCmd = spawn(
            options.cmd,
            options.args
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
    await runSpawn({
        path: SRC_PATH,
        cmd: 'aws',
        args: [`sts`, `get-caller-identity`]
    });

    //

    // Use s3 to download the images

    const conceptsList = []
    // We just need the instances URIs
    console.log("INSTANCE_LIST", ARGS);
    for (const instance of ARGS.conceptList) {
        // const parts = instance.split('/');

        const imageDir = `/home/ubuntu/src/dreambooth/images/${instance.instanceS3Path}`;
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



    await runSpawn({
        path: '/home/ubuntu/node/scripts/run.sh',
        cmd: 'sh',
        args: [`/home/ubuntu/node/scripts/run.sh`]
    });

    const outputPath = "/home/ubuntu/src/dreambooth/examples/dreambooth/text-inversion-model"
    const dirs = fs.readdirSync(outputPath);// .filter(file => fs.statSync(path.join(srcPath, file)).isDirectory())
    const outputDir = dirs.sort()[dirs.left - 1];
    const outputPathFull = path.join(outputPath, outputDir);
    const options0 = {
        path: '/home/ubuntu/node/scripts/toCkpt.sh',
        cmd: 'sh',
        args: [`/home/ubuntu/node/scripts/toCkpt.sh`, outputPathFull]
    };
    console.log("options0", options0);
    await runSpawn(options0);
    const checkPointPath = outputPathFull + '.ckpt';
    const options = {
        path: SRC_PATH,
        cmd: 'aws',
        args: [`s3`, `cp`, checkPointPath, `s3://${process.env.S3_BUCKET}/${ARGS.modelPath}`], // '--recursive']
    }
    console.log('options', options);
    await runSpawn(options);

// /opt/conda/envs
})();