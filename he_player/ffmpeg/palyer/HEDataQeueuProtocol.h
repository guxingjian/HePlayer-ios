//
//  HEDataQeueuProtocol.h
//  he_player
//
//  Created by qingzhao on 2018/9/11.
//  Copyright © 2018年 qingzhao. All rights reserved.
//

#ifndef HEDataQeueuProtocol_h
#define HEDataQeueuProtocol_h

@protocol HeDataQueueDelegate<NSObject>

- (void)dataQueueStartCacheData;
- (void)dataQueueReachMaxCapacity;

@end

#endif /* HEDataQeueuProtocol_h */
