package com.disabled.common;

import lombok.Getter;
import lombok.Setter;

/**
 * 페이징 기능 공통기능 구현
 * 
 */
@Getter
@Setter
public class Paging {

		// 입력 파라미터
		private Integer page;        // 1-base
	    private Integer size;        // pageSize
	    private Integer totalCount;  // 전체 데이터 갯수
	    private Integer blockSize;   // 페이지 버튼 개수

	    // 계산 결과
	    private Integer totalPages;  // 전체 데이터 기준으로 계산된 총 페이지 수
	    private Integer offset;      // 현재 페이지에서 데이터를 가져오기 시작할 시작 인덱스
	    private Integer limit;       // 한 페이지에 보여줄 데이터(게시글) 갯수
	    private Integer startRow;    // 1-base (옵션)
	    private Integer endRow; 

	    private Integer startPage;   // 페이지 네비 구간 시작
	    private Integer endPage;     // 페이지 네비 구간 끝
	    private boolean hasPrevBlock;
	    private boolean hasNextBlock;
	    private Integer prevPage;    // 이전 블록의 시작-1
	    private Integer nextPage;    // 다음 블록의 끝+1

	    private boolean hasPrevPage;
	    private boolean hasNextPage;
	    private boolean isFirst;
	    private boolean isLast;
	    
	    // 기본 생성자(하위 클래스/마이바티스용). blockSize=10 고정.
	    protected Paging() {
	        this.page = 1;
	        this.size = 10;
	        this.totalCount = 0;
	        this.blockSize = 10;
	        compute();
	    }
	    
	    // 생성자
	    public Paging(Integer page, Integer size, Integer totalCount ) {
	        this.page = Math.max(1, page);
	        this.size = Math.max(1, size);
	        this.totalCount = Math.max(0, totalCount);
	        this.blockSize = 10; // blocksize 기본값 : 10
	        compute();
	    }
	    
	    // 생성자
	    public Paging(Integer page, Integer size, Integer totalCount, Integer blockSize ) {
	        this.page = Math.max(1, page);
	        this.size = Math.max(1, size);
	        this.totalCount = Math.max(0, totalCount);
	        this.blockSize = Math.max(1, blockSize);
	        compute();
	    }
	    
	    // 전체 데이터 갯수 갱신
	    public void computeWithTotal(int totalCount) {
	        this.totalCount = Math.max(0, totalCount);
	        compute();
	    }
	    
	    /** 
	     * totalPages, limit, offset 계산 로직 
	     * 
	     * */
	    protected void compute() {
	        // 총 페이지
	        this.totalPages = (int) Math.max(1, Math.ceil(totalCount / (double) size));
	        // page 보정
	        if (totalCount > 0 && page > totalPages) {
	            page = totalPages;
	        }

	        // OFFSET/LIMIT
	        this.offset = (page - 1) * size;
	        this.limit = size;

	        // 행 범위(옵션)
	        this.startRow = totalCount == 0 ? 0 : offset + 1;
	        this.endRow = Math.min(offset + size, totalCount);

	        // 네비게이션 블록
	        int currentBlock = (int) Math.ceil(page / (double) blockSize);
	        this.startPage = (currentBlock - 1) * blockSize + 1;
	        this.endPage = Math.min(startPage + blockSize - 1, totalPages);
	        this.hasPrevBlock = (startPage > 1);
	        this.hasNextBlock = (endPage < totalPages);
	        this.prevPage = hasPrevBlock ? startPage - 1 : 1;
	        this.nextPage = hasNextBlock ? endPage + 1 : totalPages;

	        // 단일 이전/다음
	        this.hasPrevPage = (page > 1);
	        this.hasNextPage = (page < totalPages);
	        this.isFirst = (page == 1);
	        this.isLast = (page == totalPages);
	    }
	    
	    // 페이지 값 재조정
	    public void currectionPage() {
	    	int lastPage = (int) Math.ceil(this.totalCount / (double) this.size);
	    	if(lastPage < 1) lastPage = 1;
	    	int currentPage = Math.min(Math.max(this.page, 1),lastPage);
	    	this.offset = (currentPage - 1 ) * this.size;
	    	this.limit = size;
	    }
}
