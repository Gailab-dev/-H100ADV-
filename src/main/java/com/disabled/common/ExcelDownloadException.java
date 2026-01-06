package com.disabled.common;

import com.disabled.model.ExcelErrorCode;

public class ExcelDownloadException extends RuntimeException{
    
    private static final long serialVersionUID = 1L;
	
	private final ExcelErrorCode errorCode;

    public ExcelDownloadException(ExcelErrorCode errorCode) {
        super(errorCode.getMessage());
        this.errorCode = errorCode;
    }
    
    public ExcelDownloadException(ExcelErrorCode errorCode, Throwable cause) {
        super(errorCode.getMessage(), cause);
        this.errorCode = errorCode;
    }

    public ExcelErrorCode getErrorCode() {
        return errorCode;
    }
}
