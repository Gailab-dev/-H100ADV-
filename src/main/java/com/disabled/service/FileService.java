package com.disabled.service;

import java.io.File;

public interface FileService {
	String convertPathByOS(String filePath);
	String extractDirectoryPath(String filePath);
	String ensureDirectory(String inputPath);
	String makePullPath(String filePath);
	void isCanonicalPath(File file);
	void isExistFilePath(File file);
}
