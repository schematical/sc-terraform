const fs = require('fs');

const { spawn } = require('child_process');
const express = require('express')
const app = express()
const port = 8080

app.get('/ping', (req, res) => {
    console.log("PING")
    res.send('Hello World!')
})
app.post('/invocations', async (req, res) => {
    console.log("req.body: ", req.body);
    await runSpawn({
        path: '/home/ubuntu/src/run.sh',
        cmd: '/opt/conda/install/bin/conda',
        args: ["run", "--no-capture-output", "-n", "ldm", "/bin/bash", "-c", `/home/ubuntu/src/run.sh ${process.argv[2]} \"${process.argv[3]}\" ${process.argv[4]}`]
    });
})
app.listen(port, () => {
    console.log(`Example app listening on port ${port}`)
});
/*const SRC_PATH = '/home/ubuntu/src/dreambooth/environment.yaml';
const CONDA_LDM_DIR = '/opt/conda/install/envs/ldm';
const CONDA_DIR = '/opt/conda/install';
const MODEL_PATH = '/home/ubuntu/src/model.ckpt';*/
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
            return reject(err);
        });

        mainCmd.on('close', (code) => {
            console.log(`child process ${options.path} exited with code ${code}`);
            return resolve();
        });
    });
}