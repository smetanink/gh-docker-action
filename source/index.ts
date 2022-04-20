import FS from 'fs';
import Path from 'path';

function getFiles(folder: string) {
    const files = FS.readdirSync(folder);
    for (const file of files) {
        const absolute = Path.join(folder, file);
        if (FS.statSync(absolute).isDirectory()) {
            getFiles(absolute);
        } else {
            console.log(absolute);
        }
    }
}

console.log('>>> __filename:', __filename);
getFiles(process.env.INPUT_FOLDER || __dirname);