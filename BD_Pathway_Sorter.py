import os,shutil,re
import ij


dir1 = ij.io.DirectoryChooser("Select parent directory to BD Folders");
dir2 = ij.io.DirectoryChooser("Select output location");

filepath = dir1.getDirectory();
newpath = dir2.getDirectory();

if not os.path.exists(newpath):
	os.mkdir(newpath);
	
wells = os.listdir(filepath);

for well in wells:
        if os.path.isdir(os.path.join(filepath,well)):
                print(well);
                files = os.listdir(os.path.join(filepath,well));
                for fname in files:
                        match = re.search(r'n0+',fname);
                        if match:
                                shutil.copy2(os.path.join(filepath,well,fname),os.path.join(newpath,well+fname));

#command = 'C:\\Users\\whitehead\\Documents\\Fiji\\Fiji.app\\fiji-win64.exe -macro stack_BD.ijm ' + newpath + '\\'
#os.system(command);