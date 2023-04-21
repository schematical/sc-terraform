const fs = require('fs');

const { spawn } = require('child_process');
const SRC_PATH = '/home/ubuntu/src/dreambooth/environment.yaml';
const CONDA_LDM_DIR = '/opt/conda/install/envs/ldm';
const CONDA_DIR = '/opt/conda/install';
const MODEL_PATH = '/home/ubuntu/src/model.ckpt';
const runSpawn = async (options) => {
    return new Promise((resolve, reject) => {
        console.log("Did not find " + options.path + " installing");

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

    await runSpawn({
        path: '/home/ubuntu/node/scripts/run.sh',
        cmd: 'sh',
        args: [`/home/ubuntu/node/scripts/run.sh`,  process.argv[2],  process.argv[3], process.argv[4]]
    });
// /opt/conda/envs
})();