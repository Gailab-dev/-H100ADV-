package com.disabled.mapper;

import java.util.Map;
import org.apache.ibatis.annotations.Param;
import org.egovframe.rte.psl.dataaccess.mapper.Mapper;

@Mapper
public interface SpatialContextMapper {
    Map<String, Object> getContext(@Param("evId") int evId);
    void saveBoundary(Map<String, Object> values);
    void deleteBoundary(@Param("deviceId") int deviceId);
    void savePose(Map<String, Object> values);
    void deletePose(@Param("evId") int evId);
}
