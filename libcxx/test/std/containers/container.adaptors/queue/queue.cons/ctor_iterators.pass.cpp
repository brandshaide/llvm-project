//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

// <queue>

#include <queue>
#include <cassert>
#include <cstddef>

#include "test_macros.h"

template <class C>
C
make(int n)
{
    C c;
    for (int i = 0; i < n; ++i)
        c.push_back(i);
    return c;
}

int main(int, char**)
{
    {
        std::deque<int> d = make<std::deque<int> >(5);
        std::queue q(d.begin(), d.end());
        static_assert(std::is_same_v<decltype(q)::value_type, int>);
        assert(q.size() == 5);
        for (std::size_t i = 0; i < d.size(); ++i)
        {
            assert(q.front() == d[i]);
            q.pop();
        }
    }
    {
        std::deque<int> d = make<std::deque<int> >(5);
        std::deque<int> e = make<std::deque<int> >(5);
        std::queue q(d.begin(), d.end(), std::move(e));
        static_assert(std::is_same_v<decltype(q)::value_type, int>);
        assert(q.size() == 10);
        for (std::size_t i = 0; i < e.size(); ++i)
        {
            assert(q.front() == e[i]);
            q.pop();
        }
        for (std::size_t i = 0; i < d.size(); ++i)
        {
            assert(q.front() == d[i]);
            q.pop();
        }
    }

  return 0;
}