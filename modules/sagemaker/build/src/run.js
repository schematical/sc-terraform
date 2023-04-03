const fs = require('fs');

const { spawn } = require('child_process');
const express = require('express')
const bodyParser = require("body-parser");
const app = express()
const port = 8080
app.use(bodyParser.json());
app.get('/ping', (req, res) => {
    console.log("PING")
    res.send('Hello World!')
})
app.post('/invocations', async (req, res) => {
    console.log("req.body: ", req.body);
    console.log("req.headers: ", req.headers);
    await runSpawn({
        path: '/home/ubuntu/src/run.sh',
        cmd: '/opt/conda/install/bin/conda',
        args: ["run", "--no-capture-output", "-n", "ldm", "/bin/bash", "-c", `/home/ubuntu/src/run.sh \"${req.body.output_bucket}\" \"${req.body.output_path}\" \"${req.body.prompt}\" -1`]
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
            return reject(new Error(data));
        });

        mainCmd.on('close', (code) => {
            console.log(`child process ${options.path} exited with code ${code}`);
            return resolve();
        });
    });
}