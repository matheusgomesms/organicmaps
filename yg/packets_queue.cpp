#include "packets_queue.hpp"
#include "../base/logging.hpp"

namespace yg
{
  namespace gl
  {
    bool Command::isDebugging() const
    {
      return m_isDebugging;
    }

    void Command::setIsDebugging(bool flag)
    {
      m_isDebugging = flag;
    }

    Command::Command()
      : m_isDebugging(false)
    {}

    Command::~Command()
    {}

    void Command::cancel()
    {}

    void Command::perform()
    {}

    Packet::Packet()
    {}

    Packet::Packet(EType type)
      : m_type(type)
    {}

    Packet::Packet(shared_ptr<Command> const & command,
                   EType type)
      : m_command(command),
        m_type(type)
    {}

    PacketsQueue::PacketsQueue()
      : m_fenceManager(5)
    {}

    struct SignalFence : public Command
    {
      int m_id;
      FenceManager * m_fenceManager;

      SignalFence(int id, FenceManager * fenceManager)
        : m_id(id), m_fenceManager(fenceManager)
      {}

      void perform()
      {
        m_fenceManager->signalFence(m_id);
      }

      void cancel()
      {
        perform();
      }
    };

    int PacketsQueue::insertFence(Packet::EType type)
    {
      int id = m_fenceManager.insertFence();
      processPacket(Packet(make_shared_ptr(new SignalFence(id, &m_fenceManager)), type));
      return id;
    }

    void PacketsQueue::joinFence(int id)
    {
      m_fenceManager.joinFence(id);
    }

    void PacketsQueue::completeCommands()
    {
      joinFence(insertFence(Packet::ECheckPoint));
    }

    void PacketsQueue::cancelCommands()
    {
      joinFence(insertFence(Packet::ECancelPoint));
    }

    void PacketsQueue::cancel()
    {
      m_packets.Cancel();
    }

    void PacketsQueue::processPacket(Packet const & packet)
    {
      if (m_packets.IsCancelled())
      {
        if (packet.m_command)
          packet.m_command->cancel();
      }
      else
        m_packets.PushBack(packet);
    }

    bool PacketsQueue::empty() const
    {
      return m_packets.Empty();
    }

    size_t PacketsQueue::size() const
    {
      return m_packets.Size();
    }
  }
}
