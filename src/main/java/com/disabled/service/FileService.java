package com.disabled.service;

import java.io.File;
import java.io.IOException;

public interface FileService {
	String convertPathByOS(String filePath);
	String extractDirectoryPath(String filePath);
	void ensureDirectory(String inputPath) throws IOException;
	String makePullPath(String filePath);
	void isCanonicalPath(File file);
	void isExistFilePath(File file);
}
