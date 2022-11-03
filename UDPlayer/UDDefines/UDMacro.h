//
//  UDMacro.h
//  TestRtspPlayer
//
//  Created by CHEN on 2020/4/30.
//  Copyright © 2020 com.hzhihui. All rights reserved.
//

#ifndef UDMacro_h
#define UDMacro_h

#include <syslog.h>
#import <Foundation/Foundation.h>

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

/* Weakify & Strongify */
#define UDWeakify(obj) __weak typeof(obj) weak_obj = obj;
#define UDStrongify(obj) __strong typeof(weak_obj) strong_obj = weak_obj;

/* Log */
#ifdef DEBUG

#define udlog_fatal(category, logFmt, ...) \
syslog(LOG_CRIT, "%s:" logFmt, category,##__VA_ARGS__); \

#define udlog_error(category, logFmt, ...) \
syslog(LOG_ERR, "%s:" logFmt, category,##__VA_ARGS__); \

#define udlog_warn(category, logFmt, ...) \
syslog(LOG_WARNING, "%s:" logFmt, category,##__VA_ARGS__); \

#define udlog_info(category, logFmt, ...) \
syslog(LOG_WARNING, "%s:" logFmt, category,##__VA_ARGS__); \

#define udlog_debug(category, logFmt, ...) \
syslog(LOG_WARNING, "%s:" logFmt, category,##__VA_ARGS__); \

#else

#define udlog_fatal(category, logFmt, ...); \

#define udlog_error(category, logFmt, ...); \

#define udlog_warn(category, logFmt, ...); \

#define udlog_info(category, logFmt, ...); \

#define udlog_debug(category, logFmt, ...); \

#endif



#endif /* UDMacro_h */
