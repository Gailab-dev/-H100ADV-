package com.disabled.mapper;

import java.util.List;
import java.util.Map;

import org.egovframe.rte.psl.dataaccess.mapper.Mapper;
import org.springframework.web.bind.annotation.RequestParam;

@Mapper
public interface LocalMapper {

	List<String> getFourDepRgNames(@RequestParam("rg_id") Integer rgId) throws IllegalStateException;

	List<String> getUserUsingLocal(List<String> fourDepRgNames) throws IllegalStateException;

	Map<String, Object> getFourDepthRgNames(@RequestParam("rg_id") Integer rgId) throws IllegalStateException;

	Integer deleteLocalTreeNode(@RequestParam("rg_id") Integer rgId) throws IllegalStateException;

	Integer InsertLocalTreeNode(Map<String, Object> map) throws IllegalStateException;

	Integer getCountUserUsingLocal(List<String> fourDepRgNames) throws IllegalStateException;

	List<Map<String, Object>> getLocalList() throws IllegalStateException;
	
}
