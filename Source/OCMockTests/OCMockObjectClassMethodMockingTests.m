/*
 *  Copyright (c) 2013-2016 Erik Doernenburg and contributors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License. You may obtain
 *  a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "OCClassMockObject.h"
#import "OCPartialMockObject.h"


#pragma mark   Helper classes

@interface TestClassWithClassMethods : NSObject
+ (NSString *)foo;
+ (NSString *)bar;
- (NSString *)bar;
@end

@implementation TestClassWithClassMethods

static NSUInteger initializeCallCount = 0;

+ (void)initialize
{
    initializeCallCount += 1;
}

+ (NSUInteger)initializeCallCount
{
    return initializeCallCount;
}

+ (NSString *)foo
{
    return @"Foo-ClassMethod";
}

+ (NSString *)bar
{
    return @"Bar-ClassMethod";
}

- (NSString *)bar
{
    return @"Bar";
}

@end


@interface TestSubclassWithClassMethods : TestClassWithClassMethods

@end

@implementation TestSubclassWithClassMethods

@end

@protocol TestProtocolForCombinedMock

- (id)delegateBar;

@end


@interface OCMockObjectClassMethodMockingTests : XCTestCase

@end


@implementation OCMockObjectClassMethodMockingTests

#pragma mark   Tests stubbing class methods

- (void)testCanStubClassMethod
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class] protocols:nil];

    [[[[mock stub] classMethod] andReturn:@"mocked"] foo];

    XCTAssertEqualObjects(@"mocked", [TestClassWithClassMethods foo], @"Should have stubbed class method.");
}

- (void)testCanExpectTheSameClassMethodMoreThanOnce
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class] protocols:nil];
    [[[[mock expect] classMethod] andReturn:@"mocked-foo"] foo];
    [[[[mock expect] classMethod] andReturn:@"mocked-foo2"] foo];

    XCTAssertEqualObjects(@"mocked-foo", [TestClassWithClassMethods foo], @"Should have stubbed class method 'foo'.");
    XCTAssertEqualObjects(@"mocked-foo2", [TestClassWithClassMethods foo], @"Should have stubbed class method 'foo2'.");
}

- (void)testClassReceivesMethodsAfterStopWasCalled
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class] protocols:nil];
    
    [[[[mock stub] classMethod] andReturn:@"mocked"] foo];
    [mock stopMocking];
    
    XCTAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should not have stubbed class method.");
}

- (void)testClassReceivesMethodAgainWhenExpectedCallOccurred
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class] protocols:nil];

   	[[[[mock expect] classMethod] andReturn:@"mocked"] foo];
   	
    XCTAssertEqualObjects(@"mocked", [TestClassWithClassMethods foo], @"Should have stubbed method.");
   	XCTAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should have 'unstubbed' method.");
}

- (void)testCanStubClassMethodFromMockForSubclass
{
    id subclassMock = [OCMockObject mockForClass:[TestSubclassWithClassMethods class] protocols:nil];

    [[[[subclassMock stub] classMethod] andReturn:@"mocked-subclass"] foo];
    XCTAssertEqualObjects(@"mocked-subclass", [TestSubclassWithClassMethods foo], @"Should have stubbed method.");
    XCTAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should not have stubbed method in superclass.");
}

- (void)testSuperclassReceivesMethodsAfterStopWasCalled
{
    id mock = [OCMockObject mockForClass:[TestSubclassWithClassMethods class] protocols:nil];

    [[[[mock stub] classMethod] andReturn:@"mocked"] foo];
    [mock stopMocking];

    XCTAssertEqualObjects(@"Foo-ClassMethod", [TestSubclassWithClassMethods foo], @"Should not have stubbed class method.");
}

- (void)testCanReplaceSameMethodInSubclassAfterSuperclassMockWasStopped
{
    id superclassMock = [OCMockObject mockForClass:[TestClassWithClassMethods class] protocols:nil];
    id subclassMock = [OCMockObject mockForClass:[TestSubclassWithClassMethods class] protocols:nil];

    [[[[superclassMock stub] classMethod] andReturn:@"mocked-superclass"] foo];
    [superclassMock stopMocking];

    [[[[subclassMock stub] classMethod] andReturn:@"mocked-subclass"] foo];
    XCTAssertEqualObjects(@"mocked-subclass", [TestSubclassWithClassMethods foo], @"Should have stubbed method");
}

- (void)testCanReplaceSameMethodInSuperclassAfterSubclassMockWasStopped
{
    id superclassMock = [OCMockObject mockForClass:[TestClassWithClassMethods class] protocols:nil];
    id subclassMock = [OCMockObject mockForClass:[TestSubclassWithClassMethods class] protocols:nil];

    [[[[subclassMock stub] classMethod] andReturn:@"mocked-subclass"] foo];
    [subclassMock stopMocking];

    [[[[superclassMock stub] classMethod] andReturn:@"mocked-superclass"] foo];
    XCTAssertEqualObjects(@"mocked-superclass", [TestClassWithClassMethods foo], @"Should have stubbed method");
}

- (void)testStubbingIsOnlyActiveAtTheClassItWasAdded
{
    // stage 1: stub in superclass affects only superclass
    id superclassMock = [OCMockObject mockForClass:[TestClassWithClassMethods class] protocols:nil];
    [[[[superclassMock stub] classMethod] andReturn:@"mocked-superclass"] foo];
    XCTAssertEqualObjects(@"mocked-superclass", [TestClassWithClassMethods foo], @"Should have stubbed method");
    XCTAssertEqualObjects(@"Foo-ClassMethod", [TestSubclassWithClassMethods foo], @"Should NOT have stubbed method");
    [superclassMock stopMocking];

    // stage 2: stub in subclass affects only subclass
    id subclassMock = [OCMockObject mockForClass:[TestSubclassWithClassMethods class] protocols:nil];
    [[[[subclassMock stub] classMethod] andReturn:@"mocked-subclass"] foo];
    XCTAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should NOT have stubbed method");
    XCTAssertEqualObjects(@"mocked-subclass", [TestSubclassWithClassMethods foo], @"Should have stubbed method");
    [subclassMock stopMocking];

    // stage 3: like stage 1; also demonstrates that subclass cleared all stubs
    id superclassMock2 = [OCMockObject mockForClass:[TestClassWithClassMethods class] protocols:nil];
    [[[[superclassMock2 stub] classMethod] andReturn:@"mocked-superclass"] foo];
    XCTAssertEqualObjects(@"mocked-superclass", [TestClassWithClassMethods foo], @"Should have stubbed method");
    XCTAssertEqualObjects(@"Foo-ClassMethod", [TestSubclassWithClassMethods foo], @"Should NOT have stubbed method");
}

- (void)testStubsOnlyClassMethodWhenInstanceMethodWithSameNameExists
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class] protocols:nil];
    
    [[[[mock stub] classMethod] andReturn:@"mocked"] bar];
    
    XCTAssertEqualObjects(@"mocked", [TestClassWithClassMethods bar], @"Should have stubbed class method.");
    XCTAssertThrows([mock bar], @"Should not have stubbed instance method.");
}

- (void)testStubsClassMethodWhenNoInstanceMethodExistsWithName
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class] protocols:nil];
    
    [[[mock stub] andReturn:@"mocked"] foo];
    
    XCTAssertEqualObjects(@"mocked", [TestClassWithClassMethods foo], @"Should have stubbed class method.");
}

- (void)testStubsCanDistinguishInstanceAndClassMethods
{
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class] protocols:nil];
    
    [[[[mock stub] classMethod] andReturn:@"mocked-class"] bar];
    [[[mock stub] andReturn:@"mocked-instance"] bar];
    
    XCTAssertEqualObjects(@"mocked-class", [TestClassWithClassMethods bar], @"Should have stubbed class method.");
    XCTAssertEqualObjects(@"mocked-instance", [mock bar], @"Should have stubbed instance method.");
}

- (void)testRevertsAllStubbedMethodsOnDealloc
{
    id mock = [[OCClassMockObject alloc] initWithClass:[TestClassWithClassMethods class] protocols:nil];

    [[[[mock stub] classMethod] andReturn:@"mocked-foo"] foo];
    [[[[mock stub] classMethod] andReturn:@"mocked-bar"] bar];

    XCTAssertEqualObjects(@"mocked-foo", [TestClassWithClassMethods foo], @"Should have stubbed class method 'foo'.");
    XCTAssertEqualObjects(@"mocked-bar", [TestClassWithClassMethods bar], @"Should have stubbed class method 'bar'.");

    mock = nil;

    XCTAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should have 'unstubbed' class method 'foo'.");
    XCTAssertEqualObjects(@"Bar-ClassMethod", [TestClassWithClassMethods bar], @"Should have 'unstubbed' class method 'bar'.");
}

- (void)testRevertsAllStubbedMethodsOnPartialMockDealloc
{
    id mock = [[OCPartialMockObject alloc] initWithClass:[TestClassWithClassMethods class] protocols:nil];
    
    [[[[mock stub] classMethod] andReturn:@"mocked-foo"] foo];
    [[[[mock stub] classMethod] andReturn:@"mocked-bar"] bar];
    
    XCTAssertEqualObjects(@"mocked-foo", [TestClassWithClassMethods foo], @"Should have stubbed class method 'foo'.");
    XCTAssertEqualObjects(@"mocked-bar", [TestClassWithClassMethods bar], @"Should have stubbed class method 'bar'.");
    
    mock = nil;
    
    XCTAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo], @"Should have 'unstubbed' class method 'foo'.");
    XCTAssertEqualObjects(@"Bar-ClassMethod", [TestClassWithClassMethods bar], @"Should have 'unstubbed' class method 'bar'.");
}

- (void)testSecondNiceClassMockDeactivatesFirst
{
    id mock1 = [[OCClassMockObject alloc] initWithClass:[TestClassWithClassMethods class] protocols:nil];
    [[[mock1 stub] andReturn:@"mocked-foo-1"] foo];

    id mock2 = [[OCClassMockObject alloc] initWithClass:[TestClassWithClassMethods class] protocols:nil];
    [mock2 makeNice];
    XCTAssertEqualObjects(@"Foo-ClassMethod", [TestClassWithClassMethods foo]);

    [mock2 stopMocking];
    XCTAssertNoThrow([TestClassWithClassMethods foo]);
}

- (void)testForwardToRealObject
{
    NSString *classFooValue = [TestClassWithClassMethods foo];
    NSString *classBarValue = [TestClassWithClassMethods bar];
    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class] protocols:nil];

    [[[[mock expect] classMethod] andForwardToRealObject] foo];
    NSString *result = [TestClassWithClassMethods foo];
    XCTAssertEqualObjects(result, classFooValue);
    XCTAssertNoThrow([mock verify]);
    
    [[[mock expect] andForwardToRealObject] foo];
    result = [TestClassWithClassMethods foo];
    XCTAssertEqualObjects(result, classFooValue);
    XCTAssertNoThrow([mock verify]);

    [[[[mock expect] classMethod] andForwardToRealObject] bar];
    result = [TestClassWithClassMethods bar];
    XCTAssertEqualObjects(result, classBarValue);
    XCTAssertNoThrow([mock verify]);
    
    [[[[mock expect] classMethod] andForwardToRealObject] bar];
    XCTAssertThrowsSpecificNamed([mock bar], NSException, NSInternalInconsistencyException, @"");

    [[[mock expect] andForwardToRealObject] bar];
    XCTAssertThrowsSpecificNamed([mock bar], NSException, NSInternalInconsistencyException, @"Did not get the exception saying andForwardToRealObject not supported");

    [[[mock expect] andForwardToRealObject] foo];
    XCTAssertThrows([mock foo]);
}

- (void)testRefusesToCreateClassMockForNilClass
{
    XCTAssertThrows(OCMClassMock(nil));
}

- (void)testInitializeIsNotCalledOnMockedClass
{
    NSUInteger countBefore = [TestClassWithClassMethods initializeCallCount];

    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class] protocols:nil];
    [mock makeNice];

    [TestClassWithClassMethods foo];
    [[mock verify] foo];

    NSUInteger countAfter = [TestClassWithClassMethods initializeCallCount];

    XCTAssertEqual(countBefore, countAfter, @"Creating a mock should not have resulted in call to +initialize");
}

- (void)testCanStubNSObjectClassMethodsIncludingAlloc
{
    TestClassWithClassMethods *dummyObject = [[TestClassWithClassMethods alloc] init];

    id mock = [OCMockObject mockForClass:[TestClassWithClassMethods class] protocols:nil];
    [[[mock stub] andReturn:dummyObject] new];

    id newObject = [TestClassWithClassMethods new];

    XCTAssertEqualObjects(dummyObject, newObject, @"Should have stubbed +new method");
}

- (void)testDoNotReleaseReturnValueTooEarlyForClassMock
{
    id mock = OCMClassMock([TestClassWithClassMethods class]);

    @autoreleasepool {
        OCMExpect([mock bar]).andReturn([NSObject new]);
    }

    id bar = [mock bar];

    XCTAssertNotNil(bar);
}

- (void)testDoNotReleaseReturnValueTooEarlyForCombinedMock
{
    id mock = OCMClassMock([TestClassWithClassMethods class], @protocol(TestProtocolForCombinedMock));

    @autoreleasepool {
        OCMExpect([mock bar]).andReturn([NSObject new]);
        OCMExpect([mock delegateBar]).andReturn([NSObject new]);
    }

    id bar = [mock bar];
    id delegateBar = [mock delegateBar];

    XCTAssertNotNil(bar);
    XCTAssertNotNil(delegateBar);
}

- (void)testStrictMockDoesNotChangeMetaclass
{
    Class mockedClass = [TestClassWithClassMethods class];

    Class originalMetaClass = object_getClass(mockedClass);

    NS_VALID_UNTIL_END_OF_SCOPE id mock = OCMStrictClassMock(mockedClass, @protocol(TestProtocolForCombinedMock));

    XCTAssertEqual(object_getClass(mockedClass), originalMetaClass);
}

- (void)testMakingMockWithNoClassMethodStubsStrictRestoresOriginalMetaclass
{
    Class mockedClass = [TestClassWithClassMethods class];

    Class originalMetaClass = object_getClass(mockedClass);

    NS_VALID_UNTIL_END_OF_SCOPE id mock = OCMClassMock(mockedClass, @protocol(TestProtocolForCombinedMock));

    [[[mock stub] andReturn:@"instance-bar-mocked"] bar];

    [mock makeStrict];

    XCTAssertEqual(object_getClass(mockedClass), originalMetaClass);
}

- (void)testMakingMockWithSutisfiedClassMethodExpectationStrictRestoresOriginalMetaclass
{
    Class mockedClass = [TestClassWithClassMethods class];

    Class originalMetaClass = object_getClass(mockedClass);

    NS_VALID_UNTIL_END_OF_SCOPE id mock = OCMClassMock(mockedClass, @protocol(TestProtocolForCombinedMock));

    NSString *const ExpectedValue = @"class-bar-mocked";

    [[[[mock expect] classMethod] andReturn:ExpectedValue] bar];

    XCTAssertEqualObjects([mockedClass bar], ExpectedValue);

    [mock makeStrict];

    XCTAssertEqual(object_getClass(mockedClass), originalMetaClass);
}

- (void)testMakingMockWithClassMethodRejectionStrictRestoresOriginalMetaclass
{
    Class mockedClass = [TestClassWithClassMethods class];

    Class originalMetaClass = object_getClass(mockedClass);

    NS_VALID_UNTIL_END_OF_SCOPE id mock = OCMClassMock(mockedClass, @protocol(TestProtocolForCombinedMock));

    [[[mock reject] classMethod] bar];

    [mock makeStrict];

    XCTAssertEqual(object_getClass(mockedClass), originalMetaClass);
}

- (void)testMakingMockWithClassMethodStubStrictDoesNotRestoreOriginalMetaclass
{
    Class mockedClass = [TestClassWithClassMethods class];

    NS_VALID_UNTIL_END_OF_SCOPE id mock = OCMClassMock(mockedClass, @protocol(TestProtocolForCombinedMock));

    Class mockMetaClass = object_getClass(mockedClass);

    [[[[mock stub] classMethod] andReturn:@"class-bar-mocked"] bar];

    [mock makeStrict];

    XCTAssertEqual(object_getClass(mockedClass), mockMetaClass);
}

- (void)testMakingMockWithUnsutisfiedClassMethodExpectationStrictDoesNotRestoreOriginalMetaclass
{
    Class mockedClass = [TestClassWithClassMethods class];

    NS_VALID_UNTIL_END_OF_SCOPE id mock = OCMClassMock(mockedClass, @protocol(TestProtocolForCombinedMock));

    Class mockMetaClass = object_getClass(mockedClass);

    [[[[mock expect] classMethod] andReturn:@"class-bar-mocked"] bar];

    [mock makeStrict];

    XCTAssertEqual(object_getClass(mockedClass), mockMetaClass);
}

- (void)testStrictRootClassMockingDoesNotBreakResolvingClassMethods
{
    // Vital for NSKeyedUnarchiver with requiresSecureCoding enabled
    NS_VALID_UNTIL_END_OF_SCOPE id mock = OCMStrictClassMock([NSObject class]);

    Class metaCls = object_getClass([TestClassWithClassMethods class]);
    IMP imp = NULL;
    SEL sel = @selector(supportsSecureCoding);

    do {
        imp = class_getMethodImplementation(metaCls, sel);
        metaCls = class_getSuperclass(metaCls);
    } while (imp != NULL);
}

@end
