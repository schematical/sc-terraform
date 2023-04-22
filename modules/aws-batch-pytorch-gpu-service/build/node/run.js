const fs = require('fs');
const { spawn } = require('child_process');
const SRC_PATH = '/home/ubuntu/src/dreambooth/environment.yaml';
const CONDA_LDM_DIR = '/opt/conda/install/envs/ldm';
const CONDA_DIR = '/opt/conda/install';
const MODEL_PATH = '/home/ubuntu/src/model.ckpt';
console.log("process.argv", process.argv);
console.log("process.argv[2]", process.argv[2]);
const INSTANCE_LIST = JSON.parse(process.argv[2]);

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
    const srcExists = fs.existsSync(SRC_PATH);
    if (!srcExists) {
        await runSpawn({
            path: SRC_PATH,
            cmd: 'sh',
            args: [`${__dirname}/scripts/install_src.sh`]
        });
    }



    const conceptsList = []
    // We just need the instances URIs
    for (const instance of INSTANCE_LIST) {
        const parts = instance.split('/');
        const instance_prompt = parts[parts.length - 1];
        const imageDir = `/home/ubuntu/images/${instance_prompt}`;
        await runSpawn({
            path: SRC_PATH,
            cmd: 'aws',
            args: [`s3`, `cp`, `s3://${process.env.S3_BUCKET}/${instance}`, imageDir, '--recursive']
        });
        conceptsList.push(  {
            "instance_prompt":      instance_prompt,
            "class_prompt":         "dog",
            "instance_data_dir":    imageDir,
            "class_data_dir":       "/home/ubuntu/images/dogs"
        })
    }
    // Use s3 to download the images
    await runSpawn({
        path: SRC_PATH,
        cmd: 'aws',
        args: [`s3`, `cp`, `s3://${process.env.S3_BUCKET}/classes/dog/`, '/home/ubuntu/images/dogs', '--recursive']
    });

    // Save the JSON to disk


    fs.writeFileSync("/home/ubuntu/concepts_list.json", JSON.stringify(conceptsList));



    await runSpawn({
        path: '/home/ubuntu/node/scripts/run.sh',
        cmd: 'sh',
        args: [`/home/ubuntu/node/scripts/run.sh`]
    });
// /opt/conda/envs
})();